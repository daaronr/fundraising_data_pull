#just_giving_data_pull_effective.R: This script downloads all current data for the EFFECTIVE charities only
#It also saves a snapshot

#Get table of target charities
charity_data_ef <- charities_effective %>%
  read_csv %>%
  #drop_na(charity_name, regno)
  drop_na(charity_name, justgiving_id) #drop if there IS no  'justgiving_id'

# Note: these names were defined in `DRfundraising_data_pull/R/set_folders.R`


#Get all fundraisers for target charities (just basic information)
fundraiser_search_data_ef <-
  map2(charity_data_ef$charity_name, charity_data_ef$justgiving_id, get_charity_fundraising_pages) %>%
  reduce(bind_rows)


#fundraiser_search_data_2018 <- fundraiser_search_data_ef %>%
 # mutate(date_created=date(CreatedDate)) %>%
  #filter(date_created>"2018-06-01")

    #Sample of 10 for testing... fundraiser_search_data_t <- tail(fundraiser_search_data_ef,n=10)
    #sample wateraid: fundraiser_search_data_w<- filter(fundraiser_search_data_ef,charity=="WaterAid")
    #fundraiser_search_data_a<-filter(fundraiser_search_data_ef,charity=="Animal Equality")

#Get info about the fundraisers
fundraising_page_data <-
  map(fundraiser_search_data_ef$Id, get_fundraising_data) %>%
  reduce(bind_rows) %>%
  left_join(fundraiser_search_data_ef, by = c('pageId' = 'Id')) %>%
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

