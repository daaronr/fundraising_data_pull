library(tidyverse)
library(httr)
library(jsonlite)
library(rlist)
library(XML)

source("my_app_id.R") #sources the file you just created with your app id on JustGiving

charities_csv <- 'effective_charities.csv' #replace with your list of preferred charities (this script currently only uses charity name and JustGiving ID)
data_folder <- 'data\\just_giving_data' #folder where the data ends up

#these file paths are defined here used to save the data at the end of this script
all_donations_file <- paste(data_folder, 'all_donations.csv', sep ='\\') 
all_fundraisers_file <- paste(data_folder, 'all_fundraisers.csv', sep ='\\')
current_donations_file <- paste(data_folder, 'current_donations.csv', sep ='\\')
current_fundraisers_file <- paste(data_folder, 'current_fundraisers.csv', sep ='\\')

get_data_from_api <- function(uri_end, 
                  host = 'api.justgiving.com',
                  app_id = my_app_id){
  data <- paste('https://', host, app_id, uri_end, sep = '') %>%
    httr::GET(.) %>%
    content(as = 'parsed')
  return(data)
}

list_to_tibble <- function(named_list, my_recursive = F){
    named_list %>%
    unlist(recursive = my_recursive) %>%
    as.data.frame.list %>%
    as.tibble %>%
    return
}

get_charity_fundraising_pages <- function(charity_name, id){
  charity_search_name <- gsub(' ', '%20', charity_name)
  uri <- paste('/v1/onesearch?q=', charity_search_name, '&i=Fundraiser&limit=9999', sep = '')
  charity_search_response <- get_data_from_api(uri)
  if(charity_search_response$Total == 0){
    return(NULL)
  }
  fundraisers_data <- charity_search_response[['GroupedResults']][[1]][['Results']] %>%
    map(list_to_tibble) %>%
    reduce(bind_rows)%>%
    mutate(charity = charity_name,
           searched_charity_id = id)
  return(fundraisers_data)
}

get_fundraising_data <- function(fundraiser_id){
  paste('/v1/fundraising/pagebyid/',fundraiser_id, sep = '') %>%
    get_data_from_api %>%
    xmlParse %>%
    xmlToList %>%
    list_to_tibble(my_recursive = T) %>%
    return
}

get_fundraiser_donations <- function(short_page_name){
  uri <- paste('/v1/fundraising/pages/', short_page_name, '/donations', sep = '')
  donation_data_response <- get_data_from_api(uri) %>%
    xmlParse %>%
    xmlToList
  if(is.null(donation_data_response[['donations']])){
    return(NULL)
  }
  results <- donation_data_response[['donations']] %>%
    map(list_to_tibble) %>%
    reduce(bind_rows) %>%
    mutate(pageShortName = short_page_name)
  return(results)
}

charity_data <- charities_csv %>%
  read_csv %>%
  drop_na(charity_name, justgiving_id)

fundraiser_search_data <-
  map2(charity_data$charity_name, charity_data$justgiving_id, get_charity_fundraising_pages) %>%
  reduce(bind_rows)

fundraising_page_data <-
  map(fundraiser_search_data$Id, get_fundraising_data) %>%
  reduce(bind_rows) %>%
  left_join(fundraiser_search_data, by = c('pageId' = 'Id')) %>%
  filter(searched_charity_id == charity.id) %>%
  select(-grep('image.', names(.))) %>%
  select(-grep('videos.', names(.)))%>%
  select(-grep('branding.', names(.))) %>%
  mutate(date_downloaded = Sys.time())

donation_data <-
  map(fundraising_page_data$pageShortName, get_fundraiser_donations) %>%
  reduce(bind_rows) %>%
  mutate(date_downloaded = Sys.time())

write_csv(fundraising_page_data, all_fundraisers_file, append = T)
write_csv(fundraising_page_data, current_fundraisers_file)
write_csv(donation_data, all_donations_file, append = T)
write_csv(donation_data, current_donations_file)
