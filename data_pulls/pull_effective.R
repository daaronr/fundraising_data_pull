#### Automated Pull for effective charities only ####
rm(list=ls())
#### Load packages ####

library(pacman)

p_load(dplyr,magrittr,purrr,tidyverse,tidyr,broom,janitor, here,glue,
       dataMaid,readr,lubridate, httr,jsonlite,rlist,XML, git2r,
       install = FALSE) #git2r is new

# Clear log file (otherwise this becomes too large for Git to handle)
# close( file( "pull_effective.log", open="w" ) )

#Set working directory
setwd(here())

#Set repo
repo <- here()

#Username for Git
#TODO: separate account to use the password for

# username <- "fundraising_data_pull@outlook.com"
# password <- "justgiving_api1"

#### Pull in the repo based in the working directory (to avoid merge conflicts) ####

# git2r::pull(repo = repo)
detach("package:git2r", unload = TRUE)

#Setting file paths and folders
source("R/set_folders.R")

#This sources the file you just created with your app id on JustGiving
source("my_app_id.R")
#This contains various functions that the other scripts need to call
source("R/functions.R")


#### Actual data pull ####

#TODO: remove user input section, decide on which subset we are using

source("R/just_giving_data_pull_effective.R")

# Change this to use bash instead
# #### Stage, commit and push changes to the Repo to use on any computer ####
# library(git2r)
# 
# #Stage changes
# git2r::add(repo, path = "fundraising_data_pull"
# )
# 
# #Stage untracked files (new files which have been created)
# num <- unlist(git2r::status()$untracked)
# if (num > 0) {
#   for (i in 1:length(unlist(git2r::status()$untracked))) {
#     git2r::add(repo, num[i])
#   }
# }
# 
# #Commit changes
# git2r::commit(repo,
#               message = paste("New effective data", Sys.Date()), all = TRUE)
# 
# #Push changes
# git2r::push(object = repo,
#             credentials = cred_user_pass(username = username,
#                                          password = password)  )
