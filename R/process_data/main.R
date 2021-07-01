#### Data tidying, combining and cleaning ####

# For use in bash scheduling scripts

library(here)

#DR: no packages have been loaded. Where is that supposed to happen? Adding in some of these, anyways, as you don't want me to put in the whole Rstuff template infrastructure, I think

library(pacman)

p_load(dplyr, magrittr, purrr, tidyverse, tidyr, broom, janitor, here, glue, dataMaid, readr, lubridate, httr, jsonlite, rlist, XML, git2r, install = FALSE ) #git2r is new

#Function to try and download
try_download <- function(url, path) {
  new_path <- gsub("[.]", "X.", path)
  tryCatch({
    download.file(url = url,
                  destfile = new_path)
  }, error = function(e) {
    print("You are not online, so we can't download")
  })
  tryCatch(
    file.rename(new_path, path
    )
  )
}

#p_load(vtable)

try_download(
  "https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/functions.R",
  here::here("code", "functions.R")
)

source(here("code", "functions.R")) # functions grabbed from web and created by us for analysis/output

# Set key folders and import packages
source(here("R", "process_data", "folders_funcs.R"))

# Reduce number of dataframes to operate on
source(here("R", "process_data", "monthly_sum.R"))

# Combine and clean data (note that this also calls clean_data.R)
source(here("R", "process_data", "combine_available_data.R"))
