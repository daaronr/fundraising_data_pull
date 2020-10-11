#This script downloads all current data for the target charities, 
#It also saves a snapshot

#Get table of target charities
charity_data <- charities_csv %>%
  read_csv %>%
  #drop_na(charity_name, regno) 
  drop_na(charity_name, justgiving_id) #drop if there IS no  'justgiving_id'

  #%>% filter(give_well_top_2017==1 | give_well_standout_2017==1)

#Get all fundraisers for target charities (just basic information)
fundraiser_search_data <-
  map2(charity_data$charity_name, charity_data$justgiving_id, get_charity_fundraising_pages) %>%
  reduce(bind_rows) 

#Note: pull only the where CharityID is one of:       822548    183708   2238024           1927037 181721   13441  181972 179        998971 1869770         181813 253  186165 54697 180

fundraiser_search_data_2018 <- fundraiser_search_data %>%
  mutate(date_created=date(CreatedDate)) %>%
  filter(date_created>"2018-06-01")
  
    #Sample of 10 for testing... fundraiser_search_data_t <- tail(fundraiser_search_data,n=10)
    #sample wateraid: fundraiser_search_data_w<- filter(fundraiser_search_data,charity=="WaterAid") 
    #fundraiser_search_data_a<-filter(fundraiser_search_data,charity=="Animal Equality") 
  
#Get info about the fundraisers
fundraising_page_data <-
  map(fundraiser_search_data$Id, get_fundraising_data) %>%
  reduce(bind_rows) %>%
  left_join(fundraiser_search_data, by = c('pageId' = 'Id')) %>%
  #dplyr::filter(unlist(Map(function(x, y) grepl(x, y), searched_charity_id, charity.registrationNumber))) %>% -- removed as already done above ... match the 'regno' ... if it is *present* in the other variable (some give several regno's) 
  select(-grep('image.', names(.))) %>%
  select(-grep('videos.', names(.)))%>%
  select(-grep('branding.', names(.))) %>%
  mutate(date_downloaded = Sys.time())

#Get all current donations on the fundraising pages
donation_data <-
  map(fundraising_page_data$pageShortName, get_fundraiser_donations) %>%
  reduce(bind_rows) %>%
  mutate(date_downloaded = Sys.time())

#Creates snapshot folders if they don't already exist
dir.create(snapshots_folder, showWarnings = FALSE)
dir.create(donations_folder, showWarnings = FALSE)
dir.create(fundraisers_folder, showWarnings = FALSE)

write_csv(fundraising_page_data, current_fundraisers_file_effective)
write_csv(donation_data, current_donations_file_effective)
#DR: I think we also want these saved as R files for our analysis; csv may lead to loss of data formats (or am I missing something?):
write_rds(fundraising_page_data,current_fundraisers_file_effective_rds)
write_csv(donation_data, current_donations_file_effective_rds)

#The code  below creates a table of data pull events. So that the most recents data is used and we retain a record of our behaviour
this_data_pull <- data.frame(date, time)
names(this_data_pull) <- c('date', 'datetime')
this_data_pull <- this_data_pull %>%
  mutate(donations_file_path = current_donations_file,
         fundraisers_file_path = current_fundraisers_file)

if(file.exists(table_of_data_pulls)){
  data_pulls <- read_csv(table_of_data_pulls)
  data_pulls <- bind_rows(data_pulls, this_data_pull) 
} else(data_pulls <- this_data_pull)
write_csv(data_pulls, table_of_data_pulls)

