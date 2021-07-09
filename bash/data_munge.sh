#!/bin/bash

# A script to combine, clean and tidy data files

Rscript R/process_data/main.R

# Push to Github
GIT=`which git` 
${GIT} pull
${GIT} add --all
${GIT} commit -m "Data munge: `date + '%Y-%m-%d'`"
${GIT} push
