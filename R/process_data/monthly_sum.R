#### Create monthly dataframes ####

# In order to avoid processing of a large number of files, instead combine data from each month

# Import necessary packages, functions and folder names
library(here)
here <- here::here

source(here::here("R", "process_data", "folders_funcs.R"))

#### Main ####

current_month <- format(floor_date(Sys.Date(), "month"), "%m-%Y")

# To avoid "invalid multibyte error" on MacOS
Sys.setlocale("LC_ALL", "C")

don_file_df <- tibble(don_files) %>%
  mutate(month = extract_dm(don_files),
         path = file.path(don_folder, don_files))

fund_file_df <- tibble(fund_files) %>%
  mutate(month = extract_dm(fund_files),
         path = file.path(fund_folder, fund_files))

pull_months <- unique(don_file_df$month)

invisible(
  lapply(pull_months, monthly_sum, dir = monthly_dons, df = don_file_df, id_col = "id") )

invisible(
  lapply(pull_months, monthly_sum, dir = monthly_fund, df = fund_file_df, id_col = "pageShortName") )