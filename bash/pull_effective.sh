#!/bin/bash

# A script to pull data from effective charities
Rscript data_pulls/pull_effective.R

# Push to Github
GIT=`which git`
${GIT} add --all
${GIT} commit -m "Data pull effective: `date +'%Y-%m-%d'`"
${GIT} push
