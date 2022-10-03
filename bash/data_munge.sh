#!/bin/bash

# A script to combine, clean and tidy data files

# Rscript R/process_data/main.R
cd R/process_data

Rscript -e "source('folders_funcs.R'); source('monthly_sum.R'); source('combine_available_data.R')"

# Push to Github
# GIT=`which git` 
# ${GIT} pull
# ${GIT} add --all
# ${GIT} commit -m "Data munge: `date +'%Y-%m-%d'`"
# ${GIT} push
