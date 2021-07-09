#### Data tidying, combining and cleaning ####

# For use in bash scheduling scripts

library(here)

# Set key folders and import packages
source(here("R", "process_data", "folders_funcs.R"))

# Reduce number of dataframes to operate on
source(here("R", "process_data", "monthly_sum.R"))

# Combine and clean data (note that this also calls clean_data.R)
source(here("R", "process_data", "combine_available_data.R"))
