#This script performs the randomisation, outputs a file listing all new treatment groups, and saves the current state of experimental pages

#Gets the file paths from the most recent data pull
latest_data_pulls <- table_of_data_pulls %>%
  read_csv %>%
  filter(datetime == max(datetime))

#Gets the most recently downloaded donations data
latest_donations <- latest_data_pulls %>%
  pull(donations_file_path) %>%
  read_csv

#Gets the most recently downloaded fundraiser data
latest_fundraisers <- latest_data_pulls %>%
  pull(fundraisers_file_path) %>%
  read_csv

#For each page summaries the basic info about the donations on it
latest_relevant_donations_data <- latest_donations %>%
  group_by(pageShortName) %>%
  summarise(total_raised = sum(amount, na.rm = T),
            donation_count = length(amount),
            first_donation_date = min(donationDate),
            first_donation_amount = amount[which(donationDate == min(donationDate))],
            average_donation_at_randomisation = mean(as.numeric(amount), na.rm = T))

#Join fundraising data with relevant donations summary
latest_relevant_data <- latest_fundraisers %>%
  select(pageShortName, charity, fundraisingTarget, expiryDate, eventDate) %>%
  left_join(latest_relevant_donations_data)

#Produces a vector of page short names that are already in the experiment (these are filtered out)
if(file.exists(all_experimental_pages)){
  previous_experimental_pages <- all_experimental_pages %>%
    read_csv
  experimental_page_names <- pull(previous_experimental_pages, pageShortName)
} else{experimental_page_names <- c()}

#Produces a table of new fundraising pages and randomaises them into treatments and control
new_pages <- latest_relevant_data %>%
  filter(!(pageShortName %in% experimental_page_names)) %>%
  filter(!is.na(first_donation_date)) %>%
  filter(first_donation_date >=experiment_start_date) %>%
  mutate(group = randomisation_protocol(first_donation_date),
         date_identified = date)

#Produces a table of treatment pages. This table will need to be updated manually as the experiment is run
treatments <- new_pages %>%
  filter(group == 'Treatment') %>%
  select(pageShortName, date_identified) %>%
  mutate(link_to_page = paste("https://www.justgiving.com/fundraising/", 
                                  pageShortName, sep = "/") ,
         additional_donated_amount = 0)

#Updates the treatment table
if(file.exists(treatments_file)){
  all_treatments <- treatments_file %>%
    read_csv %>%
    bind_rows(treatments) %>%
    distinct(pageShortName, .keep_all = T)
}else(all_treatments <- treatments)
write_csv(all_treatments, treatments_file)

#Updates the experimental pages table
if(file.exists(all_experimental_pages)){
  experimental_pages <-  bind_rows(previous_experimental_pages, new_pages)
}else(experimental_pages <- new_pages)
write_csv(experimental_pages, all_experimental_pages)

#The below puts togather and updates a table of all the donations for all the current experimental pages
#This table forms the basis for the analysis
current_experimental_donation_state <- latest_donations %>%
  left_join(experimental_pages) %>%
  filter(!is.na(charity))

if(file.exists(current_experimental_donation_state_path)){
  current_experimental_donation_state <- read_csv(current_experimental_donation_state_path) %>%
    bind_rows(current_experimental_donation_state) %>%
    distinct(pageShortName, id, .keep_all = T)
}
write_csv(current_experimental_donation_state, current_experimental_donation_state_path)
