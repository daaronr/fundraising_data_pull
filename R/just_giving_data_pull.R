library(pacman)

p_load(dplyr,magrittr,purrr,tidyverse,tidyr,broom,janitor,here,glue,
       dataMaid,readr,lubridate, httr,jsonlite,rlist,XML,optparse,
       install = FALSE)

start <- Sys.time()

source(here("my_app_id.R"))
source(here("R", "functions.R"))

parser <- OptionParser()
parser <- add_option(parser, "--out_path",
                     type = "character",
                     help = paste("Path in which to write fundraisers and donations.",
                                  "Path must be relative from repo root."))
parser <- add_option(parser, "--charity_list_path",
                     type = "character",
                     help = paste("Path to list of charities to pull data for.", 
                                  "Path must be relative from repo root."))
parser <- add_option(parser, "--date_since",
                     type = "character",
                     help = paste("Date from which to collect pages.",
                                  "Date must be in %Y-%m-%d format."))
parser <- add_option(parser, c("--new_only"), action="store_true",
                     default=FALSE, 
                     help=paste("Collect only new fundraisers (those created since yesterday)?",
                                "Default is false. Provide argument to specify true."))
parser <- add_option(parser, c("--since_last_pull"), action="store_false",
                     default=TRUE, 
                     help=paste("Collect only fundraisers created since the last pull?",
                                "Default is true. Provide argument to specify false."))

args <- parse_args(parser)

# Checking input arguments
if (!sum(is.null(args$date_since) + is.null(args$new_only)) %in% c(0,1)){
  stop("One or none of date_since, since_last_pull or new_only must be specified.")
}

if (is.null(args$out_path)){
  stop("User must specify out_path.")
}

if (is.null(args$charity_list_path)){
  stop("User must specify charity_list_path.")
}

# Setting directories and filenames ---------------------------------------
data_folder <- here(args$out_path)
snapshots_folder <- file.path(data_folder, 'just_giving_data_snapshots')

date <- Sys.Date()
time <- Sys.time()

#File and folder paths are defined here; used to save the data at the end of this script
donations_folder <- here(snapshots_folder, 'donations')
fundraisers_folder <- here(snapshots_folder, 'fundraisers')

dir.create(data_folder, showWarnings = FALSE)
dir.create(snapshots_folder, showWarnings = FALSE)
dir.create(donations_folder, showWarnings = FALSE)
dir.create(fundraisers_folder, showWarnings = FALSE)

donations_file_name <- paste('donations', date, '.csv', sep = '')
donations_file_name_rds <- paste('donations', date, '.rds', sep = '')
fundraisers_file_name <- paste('fundraisers', date, '.csv', sep = '')
fundraisers_file_name_rds <- paste('fundraisers', date, '.rds', sep = '')

donations_file_path <- here(donations_folder, donations_file_name)
donations_file_path_rds <- here(donations_folder, donations_file_name_rds)
fundraisers_file_path <- here(fundraisers_folder, fundraisers_file_name)
fundraisers_file_path_rds <- here(fundraisers_folder, fundraisers_file_name_rds)

all_experimental_pages <- here(data_folder, 'experimental_pages.csv')
table_of_data_pulls <- here(data_folder, 'data_pulls.csv')
treatments_file <- here(data_folder, 'treatments.csv')
current_experimental_donation_state_path <- here(data_folder, 'donations_to_experimental_pages.csv')

# Pulling data ------------------------------------------------------------

# Sorting out dates from which to pull pages from
if (!is.null(args$date_since)){
  pull_from_date <- as.Date(args$date_since)
  print(paste("Pulling pages created since", pull_from_date))
  
} else if (args$new_only){
  pull_from_date <- Sys.Date() - 1
  print(paste("Pulling pages created since", pull_from_date))
  
} else if (args$since_last_pull){
  last_pull <- fundraisers_folder %>%
    list.files(pattern = "*.csv") %>%
    str_extract("[0-9]{4}-[0-9]{2}-[0-9]{2}") %>%
    lubridate::ymd() %>%
    sort() %>%
    last()
  pull_from_date <- as.Date(last_pull)
  if (is.na(last_pull)){
    pull_from_date <- 0
  }
  else{
    print(paste("Pulling pages created since", pull_from_date))
  }
} else {
  # In the case where we don't wish to filter pages by created date
  pull_from_date <- 0
}

#Get table of target charities
charity_data_s <- read_csv(args$charity_list_path) %>%
  drop_na(charity_name)

#Get all fundraisers for target charities (just basic information)
fundraiser_search_data_all <-
  map2(charity_data_s$charity_name, charity_data_s$justgiving_id, get_charity_fundraising_pages) %>%
  reduce(bind_rows)

fundraiser_search_data_all <- fundraiser_search_data_all %>%
  rename(charity_name = charity) %>%
  left_join(charity_data_s, by="charity_name")

#Filter for dates given above
fundraiser_search_data_all <- fundraiser_search_data_all %>%
  filter(CreatedDate >= pull_from_date)

#temp: intermediate exports because the process takes so long:
intermed_folder <- file.path(data_folder, 'temp_downloads_data')
dir.create(intermed_folder, showWarnings = FALSE)
write.csv(fundraiser_search_data_all, here(intermed_folder, "fundraiser_search_data_all.csv"))

#Get info about the fundraisers
fundraising_page_data_all_list <-
  map(fundraiser_search_data_all$Id, get_fundraising_data)

fundraising_page_data_all_t <- fundraising_page_data_all_list %>%
  reduce(bind_rows)

# Write intermediate results
write.csv(fundraising_page_data_all_t, here(intermed_folder, "fundraising_page_data_all.csv"))

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

#Get all current donations on the fundraising pages
donation_data_all <- map(fundraising_page_data_all$pageShortName, get_fundraiser_donations) %>%
  reduce(bind_rows) %>%
  mutate(date_downloaded = Sys.time())


# Output pulled data ------------------------------------------------------

#Creates snapshot folders if they don't already exist
dir.create(snapshots_folder, showWarnings = FALSE)
dir.create(donations_folder, showWarnings = FALSE)
dir.create(fundraisers_folder, showWarnings = FALSE)

write_csv(donation_data_all, donations_file_path)
write_rds(donation_data_all, donations_file_path_rds)
write_csv(fundraising_page_data_all, fundraisers_file_path)
write_rds(fundraising_page_data_all, fundraisers_file_path_rds)

print(Sys.time() - start)