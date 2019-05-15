library(pacman)
#knitr,dplyr,tidyverse,labelled,citr,reporttools,magrittr,glue,huxtable,experiment,dataMaid,broom,janitor,here,xRStata,estimatr,xtable
p_load(dplyr,magrittr,purrr,tidyverse,tidyr,broom,janitor, here,glue,dataMaid,readr,lubridate,summarytools, httr,jsonlite,rlist,XML)

#other packages I often use: knitr,  citr, reporttools, glue, experiment, estimatr, broom, kableExtra, purrr, ggsignif, recipes, glmnet, glmnetUtils, rsample,snakecase)

#Folder holding all the raw data and files that are created for the process
data_folder <- 'data'
#File that lists the target charities with their ids
charities_csv <- file.path(data_folder, 'effective_charities.csv') #replace with your list of preferred charities (this script currently only uses charity name and JustGiving ID)
#A folder that contains all the fundraising and donation data, a new copy each time the code is run
snapshots_folder <- file.path(data_folder, 'just_giving_data_snapshots')

#In the get_current... file, We don't look at pages with first donation that comes before the...
experiment_start_date <- as.Date('2019/07/13') #REMEMBER to reset this!!
date = Sys.Date()
time = Sys.time()

#File and folder paths are defined here; used to save the data at the end of this script
donations_file <- paste('donations', date, '.csv', sep = '')
donations_file_rds <- paste('donations', date, '.rds', sep = '')
fundraisers_file <- paste('fundraisers', date, '.csv', sep = '')
fundraisers_file_rds <- paste('fundraisers', date, '.rds', sep = '')
donations_folder <- file.path(snapshots_folder, 'donations')
fundraisers_folder <- file.path(snapshots_folder, 'fundraisers')
current_donations_file <- file.path(donations_folder, donations_file)
current_donations_file_rds <- file.path(donations_folder, donations_file_rds)
current_fundraisers_file <- file.path(fundraisers_folder, fundraisers_file)
current_fundraisers_file_rds <- file.path(fundraisers_folder, fundraisers_file_rds)
all_experimental_pages <- file.path(data_folder, 'experimental_pages.csv')
table_of_data_pulls <- file.path(data_folder, 'data_pulls.csv')
treatments_file <- file.path(data_folder, 'treatments.csv')
current_experimental_donation_state_path <- file.path(data_folder, 'donations_to_experimental_pages.csv')

#This sources the file you just created with your app id on JustGiving
source("my_app_id.R")
#This contains various functions that the other scripts need to call
source("R/functions.R")
#Downloads all current data for the target charities, also saves a snapshot
source("R/just_giving_data_pull.R")

#Performs the randomisation, outputs a file listing all new treatment groups, and saves the current state of experimental pages
source("R/get_current_state_and_randomise.R")