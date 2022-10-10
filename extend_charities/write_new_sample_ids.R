library(tidyverse)
library(here)

# Write new list of charities
df <- read_csv(here("extend_charities", "justgiving_ids.csv"))

# We can verify the checks by comparing with the original list
top_1000 <- read_csv(here("extend_charities", "top_1000_list.csv"))

df %>% filter(!is.na(justgiving_id)) %>%
  head(50) %>%
  write_csv(here("data", "guardian_top_50.csv"))
