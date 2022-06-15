#Clean up and manipulate
#- Columns in correct formats (numerical, factor etc)
#- Remove boring columns
#- Improve labels
#- Useful constructions/summary variables
#- Impute values

#TODO: Some pages funds are all raised offline: impute values for high_don, sum_don ?

# Logical for 'if it is effective, raised funds, uk, seems done' ####
fdd_fd <- fdd_fd  %>%  mutate(
  d_effective =   eval(parse(text=f_effective)), #just a fancy way of using text from filters coded above
  d_raise_pos = eval(parse(text=f_pos_funds)),
#d_seems_done = eval(parse(text=f_seems_done))
#LOST this column? object 'seems_done' not found
  )

# Rename vars ####
fdd_fd %<>% dplyr::rename(charity_created = activity_charity_created)

#Drop empty factor levels
fdd_fd <- droplevels(fdd_fd)

#Arrange columns by name
fdd_fd <- fdd_fd %>% select(sort(tidyselect::peek_vars()))

#Variables back into proper formats
fdd_fd <-
  fdd_fd %>%  mutate_at(.funs = list( ~ as.POSIXct(.)), .vars = vars(c(
    "event_date", "expiry_date", "created_date"
  ))) %>%
  mutate_at( ~ factor(.), .vars = vars(c("charity_name", "hit_target", "wk_created", "mo_created", "yr_created","hr_created", "uk_lockdown"))) #Change to purr map

#Fixing NA values
fdd_fd <- fdd_fd %>%
  mutate(sum_don = replace(sum_don, is.na(sum_don), 0),
         fundraising_target = replace(fundraising_target, is.na(fundraising_target), 0),
         count_don = replace(count_don, is.na(count_don), 0),
         high_don = replace(high_don, is.na(high_don) & total_raised == 0, 0))

#Recode factor levels
fdd_fd <- fdd_fd %>% mutate(activity_type = fct_recode(activity_type, "Charity Appeal" = "CharityAppeal",
                                             "Company Appeal" = "CompanyAppeal",
                                             "In Memory" = "InMemory",
                                             "Individual Appeal" = "IndividualAppeal",
                                             "Other Celebration" = "OtherCelebration",
                                             "Other Personal Challenge (P)" = "OtherPersonalChallenge",
                                             "Other Sporting Events" = "OtherSportingEvents",
                                             "Parachuting Skydives" = "Parachuting_Skydives",
                                             "Cycling (P)" = "PersonalCycling",
                                             "Parachuting Skydives (P)" = "PersonalParachuting_Skydives",
                                             "Running Marathons (P)" = "PersonalRunning_Marathons",
                                             "Swimming (P)" = "PersonalSwimming",
                                             "Treks (P)" = "PersonalTreks",
                                             "Triathlons (P)" = "PersonalTriathlons",
                                             "Walks (P)" = "PersonalWalks",
                                             "Running Marathons" = "Running_Marathons"), #Perhaps we should simplify this and only distinguish between Personal/Non-personal sporting events?

                            charity_name = fct_recode(charity_name, "Malaria No More UK" = "MALARIA NO MORE UK",
                                                     "Save the Children" = "GSK - Save the Children partnership",
                                                      "Medecins Sans Frontieres / Doctors Without Borders (MSF)" = "Médecins Sans Frontières (UK)"))#This should simplify our data a bit

#Labeling
fdd_fd <- fdd_fd %>%
    sjlabelled::var_labels(
      activity_type = "The type of activity that the fundraiser involves.",
      charity_created = "Whether the fundraiser was set up by a registered charity or not.",
      charity_id = "Each charity has a unique identification number.",
      charity_name = "The charity which the fundraiser was set up to raise funds for.",
      country_code = "A code for the country from which the fundraiser originates.",
      count_don = "The number of donations that a page has received.",
      created_date = "When the fundraiser was created (YMD-HMS)",
      date_created = "When the fundraiser was created (YMD)",
      date_downloaded = "The date downloaded indicates the date when the data was pulled from the JustGiving API.",
      don1_date = "The date on which the first donation was made.",
      download_dur = "The number of days between the date when the data was downloaded and the expiry date.",
      dur_cdate = "The number of days between the date when the fundraiser was created (created_date) and the date on which the first donation was received.",
      dur_cd_95 = "The number of days between the fundraiser being created (created_date) and said fundraiser reaching over 95% of the page's total donations.",
      dur_edate = "The number of days between the date of the event (event_date) and the date on which the first donation was received.",
      dur_ed_95 = "The number of days between the event date and the date on which the fundraiser reached over 95% of total donations.",
      event_date = "The date of the fundraiser event.",
      event_dur = "The number of days between a fundraisers creation and the event date.",
      event_name = "The name of the fundraising event.",
      expiry_date = "The date on which the page will no longer be able to receive donations on the JustGiving site.",
      expiry_dur = "The number of days between the creation of a fundraiser and the date when the page expires.",
      first_downloaded = "When the data was first downloaded from the JustGiving API.",
      fundraising_target = "The target which has been set for the fundraiser to raise.",
      grand_total_raised_excluding_gift_aid = "The total that the page raised without gift aid.",
      high_don = "The highest donation that a page received.",
      hit_target = "A binary indicator of whether or not a page reached it's target.",
      hr_created = "The hour that the fundraiser was created.",
      med_don = "The median donation for a page." ,
      mn_don = "The mean donation for a page.",
      mo_created = "The month that the fundraiser was created.",
      owner = "Owner of the fundraising page (who set up the page).",
      page_short_name = "The unique page name for the fundraiser, effectively a page ID.",
      perc_raised = "The percentage that a fundraiser has raised, not including gift-aid.",
      prior_2020 = "Whether the page was downloaded from the API before 2020 or not.",
      pull_dur = "The number of days between a fundraisers creation and the next data pull.",
      status = "Active - Donations can still be made. Expired - donations cannot be made.",
      sum_don = "The total donations that a page received.",
      total_estimated_gift_aid = "The total amount of gift aid raised.",
      total_raised = "The total that a page raised.",
      total_raised_offline = "The total that a page raised from offline donations.",
      total_raised_percentage_of_fundraising_target = "The percentage of the pages target that was raised.",
      uk_lockdown = "Whether the page was created during the UK's national Coronavirus lockdown.",
      wday_created = "The day of the week on which the page was created.",
      wk_created = "Which week of the year that the page was created in.",
      yr_created = "The year when the page was created."
    )

  #Fix invalid multibyte errors from non-utf-8 data
  fdd_fd <-
    fdd_fd %>% mutate_at(list( ~ str_replace(., "[^[:graph:]]", " ")), .vars = vars(c("event_name", "owner", "country_code", "charity_name")))


# Make 'inf' values into NA ####


is.na(fdd_fd) <- do.call(cbind, lapply(fdd_fd, is.infinite))

