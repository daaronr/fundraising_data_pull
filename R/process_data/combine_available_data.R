start_time <- Sys.time()

library(here)
here <- here::here

#deleted because this is called in 'main' source(here::here("R", "process_data", "folders_funcs.R"))

# Due to the amount of data downloading is becoming slow may be worth changing
# Also downloading means that we don't have to have FDP cloned locally

#To avoid "invalid multibyte error" on MacOS
Sys.setlocale("LC_ALL", "C")

#### Reading in all the data from the sponsorship design analysis repo ####
donations_all <- monthly_dons %>%
  list.files(pattern = "*.csv", recursive = TRUE, full.names = TRUE) %>%
  map_df(~fread(., colClasses = "character")) %>% # Ensure there are no type errors
  filter(!duplicated(id)) %>%
  janitor::clean_names("snake") %>%
  select(!!donation_vars) %>%
  type_convert()

fundraisers_all <- monthly_fund %>%
  list.files(pattern = "*.csv", recursive = TRUE, full.names = TRUE) %>%
  map_df(~fread(., colClasses = "character")) %>%
  janitor::clean_names("snake") %>%
  distinct() %>%
  select(!!fundraiser_vars) %>%
  type_convert() # Convert types back

#Remove duplicates by picking the most recent version of fundraisers
fundraisers_all <- fundraisers_all %>%
  group_by(page_short_name) %>%
  mutate(first_downloaded = min(date_downloaded)) %>% #When a page was first downloaded
  filter(date_downloaded == max(date_downloaded) & is.na(created_date) == FALSE) %>%
  ungroup()

#Merge with info on effective charities
effective_charities_names <- readr::read_csv(here("data", "effective_charities.csv"))

donations_all <- donations_all %>%
  left_join(effective_charities_names, by = c("charity_id" = "justgiving_id")) %>%
  mutate(charity_name = as.factor(charity_name))

#### Trying to fix exchange rates (see analysis_report) ####
currency <- donations_all %>% filter(donor_local_currency_code != "GBP" |
                             NA) %>% select(donor_local_currency_code) %>% unique()

exchange <- donations_all %>%
  filter(donor_local_currency_code %in% currency$donor_local_currency_code) %>%
  group_by(donor_local_currency_code) %>%
  filter(date_downloaded == max(date_downloaded)) %>%
  group_by(donor_local_currency_code) %>%
  filter(row_number() == 1) %>%
  select(amount, donor_local_amount, donor_local_currency_code) %>%
  mutate(exchange_rate = donor_local_amount / amount) %>%
  select(donor_local_currency_code, exchange_rate)

fundraisers_all <- fundraisers_all %>%
  group_by(currency_code) %>%
  left_join(exchange, by = c("currency_code" = "donor_local_currency_code"))

fundraisers_all <- fundraisers_all %>%
  mutate(
    total_raised = if_else(
      is.na(exchange_rate),
      grand_total_raised_excluding_gift_aid,
      grand_total_raised_excluding_gift_aid / exchange_rate),
      total_raised = replace(total_raised, total_raised == -Inf, 0))

rm(exchange, currency)

fundraisers_all <-
  fundraisers_all %>% mutate(
    total_raised_percentage_of_fundraising_target = replace(
      total_raised_percentage_of_fundraising_target,
      total_raised_percentage_of_fundraising_target < 0,
      0
    ),
    fundraising_target = if_else(currency_code != "GBP", target_amount, fundraising_target),
    fundraising_target = replace(fundraising_target,
                                 fundraising_target < 0,
                                 0),
    event_date = replace(
      event_date,
      event_date > median(event_date) + years(20) |
        event_date < median(event_date) - years(20),
      # Bit arbritrary
      NA
    ),
    expiry_date = replace(expiry_date,  # Need to investigate this to decide the cut-off in a better way
                          expiry_date >= "2050-01-01",
                          NA),
    fundraising_target = replace(
      fundraising_target,
      fundraising_target >= 500000 &
        total_raised < 1000 | is.na(total_raised),
      NA
    )
  )

# Code date variables
fundraisers_all <- fundraisers_all %>%
  mutate(
    created_date = lubridate::ymd_hms(created_date),
    date_downloaded = ymd_hms(date_downloaded),
    expiry_date = ymd(expiry_date)
  ) %>%
  mutate(
    date_created = date(created_date),
    wk_created = week(created_date),
    mo_created = month(created_date),
    yr_created = year(created_date),
    wday_created = lubridate::wday(created_date, label = TRUE),
    hr_created = lubridate::hour(created_date),
    event_date = lubridate::ymd(event_date)
  )

#Variables into proper formats
fundraisers_all <- fundraisers_all %>%
  ungroup(.) %>%
  mutate_at(.funs = list( ~ as.numeric(.)), .vars = vars(matches("Raised|Estimated|Amount"))) %>%
  mutate_at(.funs = list( ~ as.factor(.)), .vars = vars(matches("Type|charity_id"))) %>%
  mutate(activity_charity_created = as.logical(activity_charity_created))



#### Creating summary variables for donations####
donations_sum <- donations_all

suppressWarnings(
donations_sum  %<>%
    group_by(page_short_name) %>% arrange(page_short_name, donation_date) %>%
    dplyr::mutate(
      amount = if_else(is.na(amount), 0, amount),
      sum_amount = sum(amount),
      cumsum = cumsum(amount),
      cumshare = cumsum / sum_amount,
      unit = 1,
      donnum = cumsum(unit),
      n_don = n(),
      cum_share_n_don = donnum / n_don,
      highest_don = max(amount)
    )
)

#Adding created_date and event_date to donations_sum for further summary variables
donations_sum <- fundraisers_all %>%
  select(created_date, event_date, page_short_name) %>%
  right_join(donations_sum, by = "page_short_name", `copy`=TRUE)

# Create summary variables for durations until event

donations_sum %<>%
  group_by(page_short_name, donation_date) %>%
  mutate(
    dur_cdate = as.double(difftime(donation_date, created_date, units = "days")),
    dur_edate = as.double(difftime(event_date, donation_date, units = "days"))
  )

donations_sum %<>%
  mutate(
    dur_cd_95 = if_else((cumshare < 0.95), Inf, min(dur_cdate)),
    dur_ed_95 = if_else((cumshare < 0.95), Inf, min(dur_edate))
    )

donations_sum %<>%
    sjlabelled::var_labels(
      dur_cdate = "duration between page creation and 'this donation'",
      dur_edate = "duration between 'this donation' and page's event date",
      dur_cd_95 =  "dur. until 95pct of donations raised (I think)",
      dur_cd_95 =  "time between 95pct of donations raised and end date (I think)"
    ) %>%
    ungroup() %>%
    group_by(page_short_name) %>%
    mutate(
      don1_date = min(donation_date),
      dur_dd1 = as.double(difftime(
        donation_date, don1_date,
      ), "days"),
      dur_dd1_11am = as.double(difftime(
        donation_date, floor_date(don1_date, unit = "day") + hours(11)), "days"),
      dur_dd1_10pm = as.double(difftime(
        donation_date, floor_date(don1_date, unit = "day") + hours(22)), "days"),
      don2_date = min(donation_date[donnum >= 2]),
      don3_date = min(donation_date[donnum >= 3]),
      don7_date = min(donation_date[donnum >= 7]),
      dur_cd_2don = min(dur_cdate[donnum >= 2]),
      dur_cd_3don = min(dur_cdate[donnum >= 3]),
      dur_cd_7don = min(dur_cdate[donnum >= 7]),
      dur_dd_7don = min(dur_dd1[donnum >= 7])
    ) %>%
    sjlabelled::var_labels(
      dur_dd1 = "days between 'this donation' and first donation on page",
      dur_dd1_11am = "days between first donation on page and 11am on page's first day",
      dur_dd1_10pm = "days between first donation on page and 10pm on page's first day",
      dur_dd_7don ="days between 1st and 7th  donation on page",
      don7_date = "date of donation 7",
      dur_cd_7don = "days until 7 donations"
    )


tryCatch({
  effective_char <- readr::read_csv("https://raw.githubusercontent.com/daaronr/fundraising_data_pull/master/data/effective_charities.csv") %>%
    select(charity_name, justgiving_id)
},  error = function(e) {
  effective_char <- readr::read_csv(here("input_data","effective_charities.csv"))
}
)

f_uk <-  "grepl('^UK$|GB|great britain|united kingdom', country_code, ignore.case = TRUE)"
f_effective <- "charity_id %in% effective_char$justgiving_id"
f_pos_funds <- "total_raised > 0"
f_dld_post_4_20 <- "date_downloaded > as.POSIXct('2020-04-01 01:00:00', tz='UTC')"

f_seems_done <-"seems_done==TRUE"


#     Median of time until 3, and until 7 donations
donations_sum_1 <- donations_sum %>%
  select(donnum, dur_cd_3don, dur_cd_7don, dur_dd_7don, charity_id, page_short_name) %>%
  mutate(
    d_effective = eval(parse(text=f_effective))) %>%
#just a fancy way of using text from filters coded above
  mutate(
    dur_cd_7don_topcode = if_else(is.na(dur_cd_7don), 10000000000, dur_cd_7don),
    dur_cd_3don_topcode = if_else(is.na(dur_cd_3don), 10000000000, dur_cd_3don)
  ) %>%
  filter(donnum == 1) %>%
  ungroup() %>%
  group_by(d_effective) %>%
#CHeck: this seems to have dropped for the not-effective ones
  mutate(med_dur_3don = median((dur_cd_3don), na.rm = TRUE),
            med_dur_7don = median((dur_cd_7don), na.rm = TRUE),
            med_dur_dd_7don = median((dur_dd_7don), na.rm = TRUE),
            p25_dur_7don = quantile(dur_cd_7don, 0.25, na.rm = TRUE),
            p25_dd_7don = quantile(dur_dd_7don, 0.25, na.rm = TRUE)
            ) %>%
  sjlabelled::var_labels(
    med_dur_7don = "Median days to 7 donations",
    med_dur_dd_7don = "Median days from 1st to 7th donation",
    p25_dur_7don = "25th percentile days to 7 donations",
    p25_dd_7don = "25th percentile days from 1st to 7th don"
    ) %>%
  select(-donnum, -dur_cd_3don, -dur_cd_7don, -dur_dd_7don)
  #Note: the result is similar whether or not we 'topcode' the pages that don't reach this number

#TODO -- just merge the above back in
donations_sum <- left_join(donations_sum, donations_sum_1, by = "page_short_name")

# donations_sum - summary variables on donations by page and by page duration

donations_sum <- donations_sum %>%
  group_by(page_short_name) %>%
  arrange(page_short_name, donation_date) %>%
  mutate(
    cumsum_avgtime_to_3 = max(
      cumsum[(donation_date > don1_date) &
               (donation_date <= don1_date +
                  duration(days=med_dur_3don)
               )]
    ),
    cumcount_avgtime_to_3 = max(
      donnum[(donation_date > don1_date) &
          (donation_date <= don1_date +
              duration(days=med_dur_3don)
          )]
    ),
    cumsum_avgtime_to_7 = max(
      cumsum[(donation_date > don1_date) &
               (donation_date <= don1_date +
                  duration(days=med_dur_7don)
#technically should be to duration of 6.5 donations
               )]
    ),
    cumcount_avgtime_to_7 = max(
      donnum[(donation_date > don1_date) &
          (donation_date <= don1_date +
              duration(days=med_dur_7don)
          )]
    ),
    cumsum_p25_dur_7don = max(cumsum[(donation_date <= created_date +
                                        duration(days=p25_dur_7don)
    )]),
    cumsum_p25_dd_7don = max(
      cumsum[(donation_date > don1_date) &
               (donation_date <= (don1_date +
                  duration(days=p25_dd_7don)
               ))]
    )
  )   %>%
  sjlabelled::var_labels(
    cumsum_avgtime_to_3 = "donations after 1st don & before 'avg time to 3 total donations'",
    cumsum_avgtime_to_7 = "donations after 1st don & before 'avg time to 7 total donations'",
    cumsum_p25_dur_7don = "before '25th pctl time to 7 total donations'",
    cumsum_p25_dd_7don = "donations after 1st don & before '25th pctl time to 7 total donations'",
    cumcount_avgtime_to_7 = "count of donations after 1st don & before '25th pctl time to 7 total donations'"
  )

#### Create 'donations between 12 hours and "mean-time-to-6 more donations"' variables (Todo) (cumsum_nextsix_less first seems good for now) ####

#Number of donations before ... page-checking times ####
donations_sum <- donations_sum %>%
  group_by(page_short_name) %>%
  arrange(page_short_name, donation_date) %>%
  mutate(
    n_don_11am_d1 = max(donnum[date(donation_date)==date(don1_date) & hour(donation_date)<11]), #num don's by 11am UK on same day as don1
    n_don_11am_d2 = max(donnum[dur_dd1_11am<1]), #... on next day
    n_don_11am = case_when(
      hour(don1_date) < 11  ~ n_don_11am_d1,
      hour(don1_date) >=11 ~ n_don_11am_d2
    ), #assign to *subsequent* 11am only
    n_don_10pm_d1 = max(donnum[date(donation_date)==date(don1_date) & hour(donation_date)<22]), #as above but for 10pm
    n_don_10pm_d2 = max(donnum[dur_dd1_10pm<1]), #... on next day
    n_don_10pm = case_when(hour(don1_date)<=22 ~ n_don_10pm_d1, hour(don1_date)>22~ n_don_10pm_d2), #assign to *subsequent* 10pm only
    n_don_check = case_when( #donations at time of checking if check 2x per day
      hour(don1_date) < 11  ~ n_don_11am_d1,
      hour(don1_date) >=11 & hour(don1_date) <22 ~ n_don_10pm_d1,
      hour(don1_date) >= 22 ~ n_don_11am_d2
    ), #assign to *subsequent* check time

    ##For next 6 donations after first donation (better: after first check time) ####
    cumsum_nextsix_lessfirst = max(
      cumsum[date(donation_date)>date(don1_date)
             & donnum>1 & donnum<=7] ),

    ##Before timings after first donations ####
    cumsum_11am_d1 = max(cumsum[date(donation_date)==date(don1_date) & hour(donation_date)<11]),
    cumsum_11am_d2 = max(cumsum[dur_dd1_11am<1]),
    cumsum_11am = case_when( hour(don1_date) < 11  ~ cumsum_11am_d1,  hour(don1_date) >=11 ~ cumsum_11am_d2), #assign to *subsequent* 11am only
    cumsum_10pm_d1 = max(cumsum[date(donation_date)==date(don1_date) & hour(donation_date)<22]),
    cumsum_10pm_d2 = max(cumsum[dur_dd1_10pm<1]),
    cumsum_10pm = case_when(hour(don1_date)<=22 ~ cumsum_10pm_d1, hour(don1_date)>22~ cumsum_10pm_d2), #assign to *subsequent* 10pm only
    cumsum_check = case_when(
      hour(don1_date) < 11  ~ cumsum_11am_d1,  hour(don1_date) >=11 & hour(don1_date) <22 ~ cumsum_10pm_d1, hour(don1_date) >= 22 ~ cumsum_11am_d2 ) #assign to *subsequent* check time
  ) %>%
  sjlabelled::var_labels(
    cumsum_nextsix_lessfirst = "Sum of next 6 donations after first donation") %>%
ungroup()


#### Average donation at 'check times' ####

donations_sum <-  donations_sum %>%
  mutate(
    av_don_check = cumsum_check/n_don_check,
    av_don_11am_d1 = cumsum_11am_d1/n_don_11am_d1,
    av_don_10pm_d1= cumsum_10pm_d1/n_don_10pm_d1
    ) %>%
  mutate(
    across(
      matches("av_don_"),
      ~ case_when(
        is.na(.) ~  0,
        is.infinite(.) ~ 0,
        TRUE ~ .
      )
    )
  )

#### recode all sum and count variables with missing/inf values to 0 ####

donations_sum <- donations_sum %>%
  mutate(
    across(
        matches("cumsum_|cumcount_"),
         ~ case_when(
           is.na(.) ~  0,
           is.infinite(.) ~ 0,
           TRUE ~ .
         )
    )
  ) %>%
  mutate(
    across(
      matches("n_don_"),
      ~ if_else(is.na(.),0,.)
    )
  )


#### Collapse to 1 row per fundraiser, get key statistics for fundraiser (can merge back to fundraisers_all) ####
Fdd_f <-
  list(.vars = lst(
    "amount",
    c("don1_date", "dur_cdate", "dur_edate"),
    c("dur_ed_95", "dur_cd_95")
  ),
  .funs = lst(
    list(
      count_don = ~ n(),
      high_don = ~ max(.),
      low_don = ~ min(.),
      sum_don = ~ sum(.),
      med_don = ~ median(.),
      mn_don = ~ mean(.)
    ),
    ~ first(.),
    ~ min(.)
  ))  %>%
  pmap( ~ donations_sum %>% group_by(page_short_name) %>%
          summarise_at(.x, .y)) %>%
  reduce(inner_join, by = "page_short_name") %>%
  ungroup()


#merge back in other key created variables:

#(donations 'summed' data with 1 row per fundraiser)
f_donations_sum <- donations_sum[!duplicated(donations_sum$page_short_name),] %>%
  dplyr::select(-charity_name, -created_date, -currency_code, -date_downloaded, -event_date, -don1_date, -dur_cdate, -dur_edate, -dur_ed_95, -dur_cd_95)

fdd_fd0 <- left_join(fundraisers_all, Fdd_f)

fdd_fd <- fdd_fd0 %>%
  left_join(., f_donations_sum, by="page_short_name")


#Removing redundant (not needed) variables
fdd_fd %<>%
dplyr::select( owner, charity_id, total_raised, d_effective,
               matches(
    "status|first|don|date|created|page_short_name|charity_name|gift_aid|percentage|country_code|target|date_|dur_|_don|_created|event_name|activity_type|total_raised_offline|av_don_|cumsum_|cumcount",
    ignore.case = FALSE
  ),
  -target_amount
)

fdd_fd %<>%  mutate(
    across(
      matches("cumsum_"),
      ~ case_when(
        is.na(.) ~  0,
        is.infinite(.) ~ 0,
        TRUE ~ .
      )
    )
  ) %>%
  mutate(
    across(
      matches("n_don_"),
      ~ if_else(is.na(.),0,.)
    )
  ) %>%
mutate(
  across(
    matches("av_don_"),
    ~ case_when(
      is.na(.) ~  0,
      is.infinite(.) ~ 0,
      TRUE ~ .
    )
  )
)

  #Filter out duplicates
fdd_fd %<>% distinct(.keep_all = TRUE)


#### Calculating new variables for analysis. ####
fdd_fd %<>%
  mutate(
    download_dur = as.numeric(as.duration(interval(
      date_downloaded, expiry_date
    )), "days"),
    expiry_dur = as.numeric(as.duration(interval(
      created_date, expiry_date
    )), "days"),
    pull_dur = as.numeric(as.duration(interval(
      created_date, first_downloaded
    )), "days"),
    hit_target = if_else(total_raised >= fundraising_target, 1, 0),
    perc_raised = (total_raised / fundraising_target) * 100,
    perc_raised = replace(perc_raised, perc_raised %in% c(NA, NaN, Inf), 0),
    event_dur = as.numeric(as.duration(interval(
      created_date, event_date
    )), "days"),
    uk_lockdown = if_else(created_date %within% interval("2020-03-23", "2020-05-10"), 1, 0),
    prior_2020 = as.factor(if_else(first_downloaded >= "2020-01-01",
                                   "Pulled during or after 2020",
                                   "Pulled prior to 2020"))) #When did lockdown end officially?



#### Further analysis and scoping features ####

fdd_fd <- fdd_fd %>%
  mutate(
    time_to_next_don_proxy =
      as.duration(
        ymd_hms(don2_date) - ymd_hms(don1_date)
        #ymd_hms(don3_date) - ymd_hms(don1_date)
      )/ ddays(1)
  )


fdd_fd <- fdd_fd %>%
    filter(!is.na(dur_cd_7don)) %>%
  group_by(d_effective) %>%
  mutate(
    mean_time_to_7 = mean(dur_cd_7don, na.rm=TRUE),
    med_time_to_7 = median(dur_cd_7don, na.rm = TRUE),
  ) %>%
  ungroup()

fdd_fd %<>% mutate(created_mo = floor_date(created_date, "months"))

source(here("R", "process_data", "clean_data.R"), local = TRUE)

end_time <- Sys.time()
duration = end_time - start_time
print(duration)
saveRDS(fdd_fd, file = "rds/fundraisers_w_don_info")
saveRDS(donations_all, file = "rds/donations_all")
saveRDS(fundraisers_all, file = "rds/fundraisers_all")

