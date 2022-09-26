library(tidyverse)
library(googlesheets4)
library(here)
library(snakecase)

out_path <- here("extend_charities", "top_1000_list.csv")

if (file.exists(out_path)){
  print("List file exists already")
  quit()
}

top_chars <- read_sheet("https://docs.google.com/spreadsheets/d/1nQ1Oykkpbu4MtVvwLGCj1hYs8uAZCWPKup_c7g1KvLg/edit#gid=2",
                        sheet = "2010 by total income") %>%
  rename_with(snakecase::to_snake_case)

# Sort by voluntary income
top_chars <- top_chars %>% arrange(desc(voluntary_income))

# Change charity name to title case
top_chars <- mutate(top_chars, charity_name = to_title_case(charity_name))

# Join with existing charity IDs
charity_sample <- read_csv(here("data", "charity_sample.csv")) %>% 
  mutate(charity_name = to_title_case(charity_name)) %>%
  select(charity_name, justgiving_id)

top_chars <- left_join(top_chars, charity_sample, by = "charity_name")

# Write file
write_csv(top_chars, out_path)
