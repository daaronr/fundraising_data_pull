#### Script for running pull every 24 hours ####
rm(list=ls())
#### Load packages ####

library(pacman)

p_load(dplyr,magrittr,purrr,tidyverse,tidyr,broom,janitor, here,glue,
       dataMaid,readr,lubridate,summarytools, httr,jsonlite,rlist,XML, git2r,
       taskscheduleR) #git2r is new

#Set working directory
setwd("\\\\isad.isadroot.ex.ac.uk/UOE/User/fundraising_data_pull")

#Set repo
repo <- "\\\\isad.isadroot.ex.ac.uk/UOE/User/fundraising_data_pull"

#Username for Git
#TODO: separate account to use the password for

username <- "fundraising_data_pull@outlook.com"
password <- "justgiving_api1"

#### Pull in the repo based in the working directory (to avoid merge conflicts) ####

git2r::pull(repo = "\\\\isad.isadroot.ex.ac.uk/UOE/User/fundraising_data_pull")
detach("package:git2r", unload = TRUE)


#### Folder and filename setup, bring in functions ####

#Folder holding all the raw data and files that are created for the process
data_folder <- 'data'

#File that lists the target charities with their ids
charities_csv <- file.path(data_folder, 'effective_charities.csv') #replace with your list of preferred charities (this script currently only uses charity name and JustGiving ID)

charities_csv_sample <- file.path(data_folder, 'charity_sample.csv')
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
donations_folder <- file.path(snapshots_folder, 'donations')
fundraisers_folder <- file.path(snapshots_folder, 'fundraisers')
current_donations_file <- file.path(donations_folder, donations_file)
current_donations_file_rds <- file.path(donations_folder, donations_file_rds)
current_fundraisers_file <- file.path(fundraisers_folder, fundraisers_file)
current_fundraisers_file_rds <- file.path(fundraisers_folder, fundraisers_file_rds)

#'_s' for 'sample' ... versions including top-10 non-effective
donations_file_s <- paste('donations_s', date, '.csv', sep = '')
donations_file_s_rds <- paste('donations_s', date, '.rds', sep = '')
fundraisers_file_s <- paste('fundraisers_s', date, '.csv', sep = '')
fundraisers_file_s_rds <- paste('fundraisers_s', date, '.rds', sep = '')
current_donations_file_s <- file.path(donations_folder, donations_file_s)
current_donations_file_s_rds <- file.path(donations_folder, donations_file_s_rds)
current_fundraisers_file_s <- file.path(fundraisers_folder, fundraisers_file_s)
current_fundraisers_file_s_rds <- file.path(fundraisers_folder, fundraisers_file_s_rds)

all_experimental_pages <- file.path(data_folder, 'experimental_pages.csv')
table_of_data_pulls <- file.path(data_folder, 'data_pulls.csv')
treatments_file <- file.path(data_folder, 'treatments.csv')
current_experimental_donation_state_path <- file.path(data_folder, 'donations_to_experimental_pages.csv')

#This sources the file you just created with your app id on JustGiving
source("my_app_id.R")
#This contains various functions that the other scripts need to call
source("R/functions.R")


#### Actual data pull ####

#TODO: remove user input section, decide on which subset we are using

source("R/just_giving_data_pull_sampler.R")

####Randomisation and 'treatment instruction output ####

#Performs the randomisation, outputs a file listing all new treatment groups, and saves the current state of experimental pages
source("R/get_current_state_and_randomise.R")


#### Stage, commit and push changes to the Repo to use on any computer ####
library(git2r)

#Stage changes
git2r::add(repo, path = "fundraising_data_pull"
)

#Stage untracked files (new files which have been created)
num <- unlist(git2r::status()$untracked)
if (num > 0) {
for (i in 1:length(unlist(git2r::status()$untracked))) {
  git2r::add(repo, num[i])
}
}

#Commit changes
git2r::commit(repo,
              message = as.character(Sys.Date()), all = TRUE)

#Push changes
git2r::push(object = repo,
            credentials = cred_user_pass(username = username,
                                         password = password)  )
