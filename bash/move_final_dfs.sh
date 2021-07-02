#!/bin/bash

# A script to move dataframes which are exported from running combine_available_data.R

# Change directory to that of the current file
cd "$(dirname "$0")"

source_dir=../rds # Folder to move from
dest_dir=../../sponsorship_design_analysis/just_giving_power_regression_blocking_scoping/rds/ # Folder to move to

# Bash script to move the following dataframes into the sponsorship_design_analysis repo
# - donations_all
# - fundraisers_all
# - fundraisers_w_don_info

cp ${source_dir}"/donations_all" ${source_dir}"/fundraisers_all" ${source_dir}/"fundraisers_w_don_info" ${dest_dir}
