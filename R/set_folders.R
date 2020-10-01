#### Folder and filename setup, bring in functions ####

#Folder holding all the raw data and files that are created for the process
data_folder <- 'data'

#File that lists the target charities with their ids
charities_csv <- file.path(data_folder , 'effective_charities.csv') #replace with your list of preferred charities (this script currently only uses charity name and JustGiving ID)

charities_csv_sample <- file.path(data_folder, 'charity_sample.csv')
# This adds effective and otp-10 charities
# 1 Apr 2020: I quickly constructed this by adding from the list here: https://yougov.co.uk/ratings/politics/popularity/charities-organisations/all, selecting from the top-10 charities only

#A folder that contains all the fundraising and donation data, a new copy each time the code is run
snapshots_folder <- file.path(data_folder, 'just_giving_data_snapshots')

#In the get_current... file, We don't look at pages with first donation that comes before the
experiment_start_date <- as.Date('2018/04/13') #REMEMBER to reset this!!
date = Sys.Date()
time = Sys.time()

#File and folder paths are defined here; used to save the data at the end of this script
donations_file <- paste('donations', date, '.csv', sep = '')
donations_file_rds <- paste('donations', date, '.rds', sep = '')
fundraisers_file <- paste('fundraisers', date, '.csv', sep = '')
fundraisers_file_rds <- paste('fundraisers', date, '.rds', sep = '')

#'_s' for 'sample' ... versions including top-10 non-effective
donations_file_s <- paste('donations_s', date, '.csv', sep = '')
donations_file_s_rds <- paste('donations_s', date, '.rds', sep = '')
fundraisers_file_s <- paste('fundraisers_s', date, '.csv', sep = '')
fundraisers_file_s_rds <- paste('fundraisers_s', date, '.rds', sep = '')

#As we are now doing two pulls a day we need to make sure our file names don't clash
if(file.exists(here(fundraisers_folder, fundraisers_file_s))) {
  donations_file_s <- paste('donations_s', date, '_', lubridate::hour(time), '.csv', sep = '')
  donations_file_s_rds <- paste('donations_s', date, lubridate::hour(time), '.rds', sep = '')
  fundraisers_file_s <- paste('fundraisers_s', date, lubridate::hour(time), '.csv', sep = '')
  fundraisers_file_s_rds <- paste('fundraisers_s', date, lubridate::hour(time), '.rds', sep = '')
}

#File paths
donations_folder <- file.path(snapshots_folder, 'donations')
fundraisers_folder <- file.path(snapshots_folder, 'fundraisers')
current_donations_file <- file.path(donations_folder, donations_file)
current_donations_file_rds <- file.path(donations_folder, donations_file_rds)
current_fundraisers_file <- file.path(fundraisers_folder, fundraisers_file)
current_fundraisers_file_rds <- file.path(fundraisers_folder, fundraisers_file_rds)


current_donations_file_s <- file.path(donations_folder, donations_file_s)
current_donations_file_s_rds <- file.path(donations_folder, donations_file_s_rds)
current_fundraisers_file_s <- file.path(fundraisers_folder, fundraisers_file_s)
current_fundraisers_file_s_rds <- file.path(fundraisers_folder, fundraisers_file_s_rds)

all_experimental_pages <- file.path(data_folder, 'experimental_pages.csv')
table_of_data_pulls <- file.path(data_folder, 'data_pulls.csv')
treatments_file <- file.path(data_folder, 'treatments.csv')
current_experimental_donation_state_path <- file.path(data_folder, 'donations_to_experimental_pages.csv')