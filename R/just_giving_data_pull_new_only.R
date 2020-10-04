#### Code for pulling in pages created since the last pull ####
start_time <- Sys.time()

fundraising_folder <- file.path('data', 'just_giving_data_snapshots','fundraisers')

#Finds the date on which the last data pull occurred so we can pull new data
last_pull <- fundraising_folder %>%
  list.files(pattern = "*.csv") %>%
  str_extract("[0-9]{4}-[0-9]{2}-[0-9]{2}") %>%
  lubridate::ymd() %>%
  sort() %>%
  last()

#Get table of target charities
charity_data_s <- charities_csv_sample %>%
  read_csv %>%
  drop_na(charity_name)

#Get all fundraisers for target charities (just basic information)
fundraiser_search_data_all <-
  map2(charity_data_s$charity_name, charity_data_s$justgiving_id, get_charity_fundraising_pages) %>%
  reduce(bind_rows)

fundraiser_search_data_all <- fundraiser_search_data_all %>%
  rename(charity_name=charity) %>%
  left_join(charity_data_s, by="charity_name")

#Filter for pages which have been created since the last data pull was conducted
fundraiser_search_data_all <- fundraiser_search_data_all %>% 
  filter(CreatedDate >= last_pull)

#temp: intermediate exports because the process takes so long:
intermed_folder <- file.path(data_folder, 'temp_downloads_data')
dir.create(intermed_folder)
write.csv(fundraiser_search_data_all, "data/temp_downloads_data/fundraiser_search_data_all.csv")

#bind in charity_data_s by charity_name to distinguish effective/ineffective

#Get info about the fundraisers
fundraising_page_data_all_list <-
  map(fundraiser_search_data_all$Id, get_fundraising_data)

fundraising_page_data_all_t <- fundraising_page_data_all_list %>%
  reduce(bind_rows)

write.csv(fundraising_page_data_all_t, "data/temp_downloads_data/fundraising_page_data_all.csv")

#note: broken up into multiple steps because of slow processing

fundraising_page_data_all <- fundraising_page_data_all_t %>%
  as.tibble() %>%
  left_join(fundraiser_search_data_all, by = c('pageId' = 'Id')) %>%
  # TRIMMED because this now seems to drop everything:
  #dplyr::filter(unlist(Map(function(x, y) grepl(x, y), searched_charity_id, charity.registrationNumber))) %>% #match the 'regno' ... if it is *present* in the other variable (some give several regno's)
  select(-grep('image.', names(.))) %>%
  select(-grep('videos.', names(.)))%>%
  select(-grep('branding.', names(.))) %>%
  mutate(date_downloaded = Sys.time())

## tab and get charityid -- these are then entered into the charity sheet manually
## <!-- #TODO -- explain this better; what was this? -->
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
fundraising_page_data_all %>% group_by(charity.name) %>% summarise(N=n(), mode.charity.id=Mode(charity.id)) %>% arrange(desc(N)) %>% print(,n=10)

#Get all current donations on the fundraising pages
donation_data_all <-
  map(fundraising_page_data_all$pageShortName, get_fundraiser_donations) %>%
  reduce(bind_rows) %>%
  mutate(date_downloaded = Sys.time())

#Creates snapshot folders if they don't already exist
dir.create(snapshots_folder, showWarnings = FALSE)
dir.create(donations_folder, showWarnings = FALSE)
dir.create(fundraisers_folder, showWarnings = FALSE)

write_csv(fundraising_page_data_all, fundraisers_file_s)
write_csv(donation_data_all, donations_file_s)
write_rds(fundraising_page_data_all, fundraisers_file_s_rds)
write_rds(donation_data_all, donations_file_s_rds)

#The code below creates a table of data pull events. So that the most recents data is used and we retain a record of our behaviour
# this_data_pull <- data.frame(date, time)
# names(this_data_pull) <- c('date', 'datetime')
# this_data_pull <- this_data_pull %>%
#   mutate(donations_file_path = current_donations_file_sample,
#          fundraisers_file_path = current_fundraisers_file_sample)

# if(file.exists(table_of_data_pulls)){
#   data_pulls <- read_csv(table_of_data_pulls)
#   data_pulls <- bind_rows(data_pulls, this_data_pull)
# } else(data_pulls <- this_data_pull)
# write_csv(data_pulls, table_of_data_pulls)

end_time <- Sys.time()
duration <- end_time - start_time
print(duration)