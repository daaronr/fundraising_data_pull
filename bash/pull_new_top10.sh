#!/bin/bash

# A script to pull the new page from top 10. Pages are defined as new if they have been created after the last data pull occurred

Rscript data_pulls/pull_new_pages.R

# Push to Github
GIT=`which git`
${GIT} pull
${GIT} add --all
${GIT} commit -m "Data pull effective: `date +'%Y-%m-%d'`"
${GIT} push
