#!/bin/bash

# A script to pull all new pages since the last pull for top 50 charities defined by the Guardian list
#cd R
Rscript R/justgiving_data_pull.R \
    --out_path=data/daily_guardian_top_50_nonrelig_noncollege \
    --charity_list=data/guardian_top_50_nonrelig_noncollege.csv \
    --new_only

# Push to Github
GIT=`which git`
${GIT} pull
${GIT} add data/daily_guardian_top_50_nonrelig_noncollege
${GIT} commit -m "Data pull Guardian top 50 (minus churches and colleges): `date +'%Y-%m-%d'`"
${GIT} push
