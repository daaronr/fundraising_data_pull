#This script downloads all current data for the target (effective) charities, as well as a sample of all other charities 
#(TODO: I may put in other sampling )
#It also saves a snapshot

#Get table of target charities
charity_data_s <- charities_csv_sample %>%
# charity_data_s <- file.path(data_folder, 'charity_sample_2only.csv') %>%
  read_csv %>%
  #drop_na(charity_name, regno) 
  drop_na(charity_name) 
  #drop_na(charity_name, justgiving_id) 

#%>% filter(give_well_top_2017==1 | give_well_standout_2017==1)

#Trying subsetting sample --- Get all fundraisers for target charities (just basic information)
#Trying to break up the sample to get the sample pages starting with numeral '1'
#This doesn't work: uri <- paste('/v1/onesearch?q=', charity_search_name, '&i=Fundraiser&limit=99&id=12922834', sep = '')
#Using the 'offset also doesn't let you get past the 9999 entry


#Get all fundraisers for target charities (just basic information)
fundraiser_search_data_s <-
  map2(charity_data_s$charity_name, charity_data_s$justgiving_id, get_charity_fundraising_pages_sample) %>%
  reduce(bind_rows) 
 
fundraiser_search_data_s <- fundraiser_search_data_s %>% 
  rename(charity_name=charity) %>% 
  left_join(charity_data_s, by="charity_name") 

#temp: intermediate exports because the process takes so long:
intermed_folder <- file.path(data_folder, 'temp_downloads_data')
dir.create(intermed_folder)
write.csv(fundraiser_search_data_s, "data/temp_downloads_data/fundraiser_search_data_s.csv")


#TODO: adjust this to cap the 'earliest date' to a consistent measure for all charities (based on the youngest earliest data that the 9999 restriction yields) 
    
#Take a sample of 20,000 fundraisers (non-effective coded as ad_hoc_david==9) plus all the effective ones
fundraiser_search_data_s_20k <- fundraiser_search_data_s %>%
  filter(ad_hoc_david==9) %>%
  sample_n(20000) %>% 
  bind_rows(filter(fundraiser_search_data_s, (ad_hoc_david!=9|is.na(ad_hoc_david))))
write.csv(fundraiser_search_data_s_20k, "data/temp_downloads_data/fundraiser_search_data_s_20k.csv")

 #bind in charity_data_s by charity_name to distinguish effective/ineffective 

#Get info about the fundraisers
fundraising_page_data_s_20K <-
  map(fundraiser_search_data_s_20k$Id, get_fundraising_data) 

fundraising_page_data_s_20Kt <- fundraising_page_data_s_20K %>%
  reduce(bind_rows) %>%
write.csv(fundraising_page_data_s_20K, "data/temp_downloads_data/fundraising_page_data_s_20k.csv")


#note: broken up into multiple steps because of slow processing

fundraising_page_data_s_20K <- fundraising_page_data_s_20Kt %>%  
  as.tibble() %>%
  left_join(fundraiser_search_data_s_20k, by = c('pageId' = 'Id')) %>%
  # TRIMMED because this now seems to drop everything: 
  #dplyr::filter(unlist(Map(function(x, y) grepl(x, y), searched_charity_id, charity.registrationNumber))) %>% #match the 'regno' ... if it is *present* in the other variable (some give several regno's) 
  select(-grep('image.', names(.))) %>%
  select(-grep('videos.', names(.)))%>%
  select(-grep('branding.', names(.))) %>%
  mutate(date_downloaded = Sys.time()) 

## tab and get charityid -- these are then entered into the charity sheet manually
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
fundraising_page_data_s_20k %>% group_by(charity.name) %>% summarise(N=n(), mode.charity.id=Mode(charity.id)) %>% arrange(desc(N)) %>% print(,n=20)

#Get all current donations on the fundraising pages
donation_data_s_20k <-
  map(fundraising_page_data_s_20k$pageShortName, get_fundraiser_donations) %>%
  reduce(bind_rows) %>%
  mutate(date_downloaded = Sys.time())

#Creates snapshot folders if they don't already exist
dir.create(snapshots_folder, showWarnings = FALSE)
dir.create(donations_folder, showWarnings = FALSE)
dir.create(fundraisers_folder, showWarnings = FALSE)

write_csv(fundraising_page_data_s_20k, current_fundraisers_file_s)
write_csv(donation_data_s_20k, current_donations_file_s)
write_rds(fundraising_page_data_s_20k, current_fundraisers_file_s_rds)
write_rds(donation_data_s_20k, current_donations_file_s_rds)

#The code  below creates a table of data pull events. So that the most recents data is used and we retain a record of our behaviour
this_data_pull <- data.frame(date, time)
names(this_data_pull) <- c('date', 'datetime')
this_data_pull <- this_data_pull %>%
  mutate(donations_file_path = current_donations_file_sample,
         fundraisers_file_path = current_fundraisers_file_sample)

if(file.exists(table_of_data_pulls)){
  data_pulls <- read_csv(table_of_data_pulls)
  data_pulls <- bind_rows(data_pulls, this_data_pull) 
} else(data_pulls <- this_data_pull)
write_csv(data_pulls, table_of_data_pulls)
