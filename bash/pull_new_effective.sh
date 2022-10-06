#!/bin/bash

# A script to pull pages created since yesterday from effective charities
# Effective charities are from data/effective_charities.csv
cd R
Rscript R/justgiving_data_pull.R \
    --outpath=data/daily_effective_data \
    --charity_list=data/effective_charities.csv

# Push to Github
GIT=`which git`
${GIT} pull
${GIT} add data/daily_effective_data
${GIT} commit -m "Data pull new effective: `date +'%Y-%m-%d'`"
${GIT} push
