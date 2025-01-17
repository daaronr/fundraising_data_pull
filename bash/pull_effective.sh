#!/bin/bash

# A script to pull all new pages since the last pull from effective charities
# Effective charities are from data/effective_charities.csv
cd R
Rscript R/justgiving_data_pull.R \
    --outpath=data/effective_data \
    --charity_list=data/effective_charities.csv

# Push to Github
GIT=`which git`
${GIT} pull
${GIT} add data/effective_data
${GIT} commit -m "Data pull effective: `date +'%Y-%m-%d'`"
${GIT} push
