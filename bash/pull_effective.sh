#!/bin/bash

# A script to pull data from effective charities
cd R
Rscript -e "source('set_folders.R'); source('my_app_id.R'); source('functions.R'); source('just_giving_data_pull_effective.R')"

# Push to Github
GIT=`which git`
${GIT} pull
${GIT} add --all
${GIT} commit -m "Data pull effective: `date +'%Y-%m-%d'`"
${GIT} push
