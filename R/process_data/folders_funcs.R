#### Import key packages ####
library(tidyverse)
library(lubridate)
library(here)
library(stringr)
library(data.table)
library(assertthat)

#### Define functions ####

# Extract date and month from file names
extract_dm <- function(files, regex = "[0-9-]+", format = "%m-%Y"){
  date <- as.Date(str_extract(files, regex))
  month <- format(as.Date(floor_date(date, "month")), format)
  
  return(month)
}

# Read in files and use dup_col to filter out duplicates based on this column
# In this case we want to ensure that each observation is the most recently downloaded version
read_remove_dupes <- function(files, id_col, filter_col) {
  
  assert_that(is.vector(files))
  assert_that(typeof(files) == "character", msg = "Files must be a character vector")
  
  df <- files %>%
    map_df(~fread(.) %>%
             mutate(across(everything(), as.character))) %>%# Avoid type errors
    distinct() %>%
    group_by(across(!!id_col)) %>% 
    filter(.data[[filter_col]] == max(.data[[filter_col]])) %>% # Syntax for using character vector as var name
    ungroup()
  return(df)
}

monthly_sum <- function(mth, dir, df, verbose=TRUE, id_col, filter_col = "date_downloaded") {
  
  # Ensure input variable types are correct
  assert_that(is.string(mth))
  assert_that(is.string(dir))
  assert_that(is.data.frame(df))
  
  DMY <- as.Date(paste("01-", mth,sep=""), format="%d-%m-%Y")
  today <- Sys.Date()
  
  # Create the new directory path
  new_dir <- paste(dir, mth, sep = "/")
  # Create a new directory if necessary
  if (!dir.exists(new_dir)){
    dir.create(new_dir)
  }
  # Initially compute all previous months
  # Compute current month to allow for new data
  if (length(list.files(new_dir)) ==0 || all(c(month(today), year(today)) == c(month(DMY), year(DMY)))) {
    
    if (verbose==TRUE){
      print(paste("Merging data for", mth))
    }
    path <- df %>%
      filter(month == mth) %>%
      dplyr::pull(path)
    
    # Initial combine of files and remove duplicates
    df <- read_remove_dupes(path, id_col = id_col, filter_col = filter_col)
    file_name <- paste(mth, ".csv", sep = "")
    file_path <- paste(new_dir, file_name, sep="/")
    
    write.csv(df, file = file_path, row.names = FALSE)
  }
}

#### Set folders and key variables ####
monthly_dons <- here("data", "just_giving_data_snapshots", "donations", "monthly_agg")
monthly_fund <- here("data", "just_giving_data_snapshots", "fundraisers", "monthly_agg")


don_folder <- here("data", "just_giving_data_snapshots", "donations")
fund_folder <- here("data", "just_giving_data_snapshots", "fundraisers")

# List all fundraiser and donations data files
don_files <- don_folder %>% #read in and combine 'all donations' from file paths defined in main.R
  list.files(pattern = "*.csv")

fund_files <- fund_folder %>%
  list.files(pattern = "*.csv")

# Define key variables
donation_vars <- c("amount", "currency_code", "donation_date", "donor_display_name", "donor_local_amount", "donor_local_currency_code", 
                   "estimated_tax_reclaim", "id", "message", "source", "charity_id", "page_short_name", "third_party_reference", "date_downloaded")

fundraiser_vars <- c("activity_charity_created", "activity_type", "charity_description", "charity_id", "charity_name", "country_code", 
                     "created_date", "currency_code", "date_downloaded", "event_date", "event_id", "event_name", "expiry_date", 
                     "fundraising_target", "grand_total_raised_excluding_gift_aid", "owner", "justgiving_id", "page_id", "page_short_name", 
                     "page_summary", "status", "target_amount","total_estimated_gift_aid", "total_raised_offline", "total_raised_online", 
                     "total_raised_percentage_of_fundraising_target", "total_raised_sms")

