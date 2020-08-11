#Here are some awesome functions used by the rest of the code. 
#They are functional

#This is a generic function that extracts data from the api using uri_end provided
get_data_from_api <- function(uri_end, 
                                       host = 'api.justgiving.com',
                                       app_id = my_app_id){
  data <- paste('https://', host, app_id, uri_end, sep = '') %>%
    httr::GET(.) %>%
    content(as = 'parsed')
  return(data)
}

#This converts a list to a tibble, it's used by the other functions below
list_to_tibble <- function(named_list, my_recursive = F){
  named_list %>%
    unlist(recursive = my_recursive) %>%
    as.data.frame.list %>%
    as_tibble %>%
    return
}

#This function creates a table of fundraising pages using a charity name and charity id
#It uses the just giving search and then checks the just giving id against each of the results
#This ensures only pages that are for that charity are selected
get_charity_fundraising_pages <- function(charity_name, id){
  charity_search_name <- gsub(' ', '%20', charity_name)
  uri <- paste('/v1/onesearch?q=', charity_search_name, '&i=Fundraiser&limit=9999', sep = '')
  print(paste('Searching for fundraisers for:', charity_name))
  charity_search_response <- get_data_from_api(uri)
  if(charity_search_response$Total == 0){
    return(NULL)
  }
  fundraisers_data <- charity_search_response[['GroupedResults']][[1]][['Results']] %>%
    map(list_to_tibble) %>%
    reduce(bind_rows)%>%
    mutate(charity = charity_name,
           searched_charity_id = id)%>%
    filter(searched_charity_id==CharityId) #filter out where id's do not match ('justgiving_id')
  return(fundraisers_data)
}

get_charity_fundraising_pages_sample <- function(charity_name, id){
  charity_search_name <- gsub(' ', '%20', charity_name)
  uri <- paste('/v1/onesearch?q=', charity_search_name, '&i=Fundraiser&limit=9999', sep = '')
  print(paste('Searching for fundraisers for:', charity_name))
  charity_search_response <- get_data_from_api(uri)
  if(charity_search_response$Total == 0){
    return(NULL)
  }
fundraisers_data <- charity_search_response[['GroupedResults']][[1]][['Results']] %>%
    map(list_to_tibble) %>%
    reduce(bind_rows)%>%
    mutate(charity = charity_name,
           searched_charity_id = id)  %>%
    filter(searched_charity_id==CharityId) #filter out where id's do not match ('justgiving_id')
  return(fundraisers_data)
}


#This takes a fundraiser's id and gets the data for it (a single row of info)
get_fundraising_data <- function(fundraiser_id){
  print(paste('Getting data for fundraiser with id', fundraiser_id))
  fundraiser <- try(paste('/v1/fundraising/pagebyid/',fundraiser_id, sep = '') %>%
    get_data_from_api %>%
    xmlParse %>%
    xmlToList %>%
    list_to_tibble(my_recursive = T))
    if(class(fundraiser) == "try-error"){
    return(NULL)
  }
    return(fundraiser)
}

#This takes a fundraiser short name and extracts all the donation data, returning them as a tibble
get_fundraiser_donations <- function(short_page_name){
  print(paste('Getting donations from fundraiser with short name', short_page_name))
  uri <- paste('/v1/fundraising/pages/', short_page_name, '/donations', sep = '')
  donation_data_response <- try(get_data_from_api(uri) %>%
    xmlParse %>%
    xmlToList)
  if(class(donation_data_response) == "try-error"){
    return(NULL)
  }
  if(is.null(donation_data_response[['donations']])){
    return(NULL)
  }
  results <- donation_data_response[['donations']] %>%
    map(list_to_tibble) %>%
    reduce(bind_rows) %>%
    mutate(pageShortName = short_page_name)
  return(results)
}

#Using the first donation date we randomise pages into treatment and control
randomisation_protocol <- function(first_donation_date){
  first_donation_second <- lubridate::second(first_donation_date)
  group <- ifelse(first_donation_second%%2==1,'Treatment', 'Control') #Odd = treatment, Even = control
  return(group)
}