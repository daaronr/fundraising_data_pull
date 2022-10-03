#### Script for running pull for new pages ####
# Can be automated by modifying the shell script pull_new_top10.sh  
#### Load packages ####

library(pacman)

p_load(dplyr,magrittr,purrr,tidyverse,tidyr,broom,janitor, here,glue,
       dataMaid,readr,lubridate, httr,jsonlite,rlist,XML,
       install = TRUE)

#### Pull in the repo based in the working directory (to avoid merge conflicts) ####

#Setting file paths and folders
source("R/set_folders.R")

#This sources the file you just created with your app id on JustGiving
source("my_app_id.R")
#This contains various functions that the other scripts need to call
source("R/functions.R")


#### Actual data pull ####

#TODO: remove user input section, decide on which subset we are using

source("R/just_giving_data_pull_new_only.R")
