# FORK of Toby's original code to interact with the JustGiving API

I (@daaronr) have adjusted it slightly (see commits) and I am using this to do data pulls and capture data used elsewhere.
Adapted by Oska to  automate the process of data pulling and munging

This should facilitate the actual running of the experiments.

# Charity seeding experiment code and process

## Pulls

- TODO: set up code for periodic data pull

## Files

**bash Folder:**
- *pull_effective.sh* pulls data on new charities (data_pulls/pull_effective.R) and pushes to Github
- *data_munge.sh* combines all data using R scripts (script from R/process_data/main.R, calling a bunch of other scripts); saves 3 RDS files 

**R Folder:** 

*Some of these may be used in the aforementioned scripts, or in scripts we will create... need to tidy up/organise* 

- *just_giving_data_pull_sampler.R* ??pulls the effective charities and takes a sample of the top 10 (redundant?).
- *just_giving_data_pull.R* pulls data on the effective and top 10.
- *just_giving_data_pull_new_only.R* pulls data on the new fundraisers only.
- *functions.R* defines functions for data pulls.
- *get_current_state_and_randomise.R* defines the randomisation process, outputs a file listing all new treatment groups, and saves the current state
- *set_folders.R* sets the folders needed to run the pulls. Folders containing data are defined in this file. 

**R/process_data:**
- *clean_data.R* performs some light column type adjustments and deals with some missing data
- *combine_available_data.R* combines all the donation and fundraising data into 3 key dataframes which have summary statistics
- *folder_funcs.R* defines functions which are used in *monthly_sum.R*
- *main.R* ties together all R files in this folder
- *monthly_sum.R* is a file to speedup the process of combining. Data on donations and fundaisers are aggregated by the month in which they were pulled and written to a total dataframe for the month. This removes the need to re-read and re-combine all past data when runnning *combine_available_data.R*. Instead only the monthly dataframes are combined, of which there are much fewer (around 20-30 instead of 300!). Note that *monthly_sum.R* will ignore previous months data but combine the current months.

## How do I make the code run? [NEEDS UPDATING -- out of date]

DR: First you need to register and create an app id on JustGiving, and save this as in a file you call
a file "my_app_id.R", containing a single line of text
```
my_app_id <- "/[ID]"
```
replacing "[ID]" with your ID, without the brackets.

Next...
/

Install the packages at the top of main.R.
Open `fundraising_data_pull.Rproj`  using R and run `main.R`.
It will take 30 - 60 minutes to download all the data; this appears to be determined by Just Giving API limits.

## What are the files created?
2 files are created (?and 4 are updated) each time data is drawn from the API, and these are stored to the folders mentioned below.

Note that we must run this regularly to retain data from expired pages (which can't be accessed through the api).

*DR: The above needs clarification. The 'all_' files are no longer being created I think*

The charities that this script uses (in effective_charities.csv) are all recommended by one or more organisations associated with effective altruism (although in some cases the lists only recommend targeting a particular part of the charity's work) [and see comment below](#notes).


*[Note, 4 Aug 2018: ATM both lists seem to include the international megacharities]*

### Created:
A table of currently live (not yet expired) JG fundraising **pages** is created in
```
{data\just_giving_data_snapshots\fundraisers}
```
...with the current date appended. This contains only those "effective" charities that have a just giving id in the effective_charities.csv file (the effective_charities.csv is in the data folder of the project).

A table of **donations** to currently live pages is created in
```
{data\just_giving_data_snapshots\donations}
```
..with the current date appended.

These files are created as a record of the state of the full sample of pages. This is done:

* in case we find issues with the code or our data collection methodology during the experiment, and

* for transparency - this data can be published as a way of allowing our entire process to be visible.


### Updated:
**data_pulls.csv** is updated after every pull with the date and the file paths of the two files created (fundraisers and donations). The most recent files referenced in this table are used to update the other files.

Note: additional details for our project [moved to private page](https://github.com/daaronr/sponsorship_design_analysis/tree/master/preregistration_plans_notes)

my_app_id <- {/your app id}

*You may need to add quotes around this, i.e.:* `my_app_id <- "/id_number"`


### Notes

The charities that this script uses (in `effective_charities.csv`) are all recommended by one or more organisations associated with effective altruism (However, this could be adjusted):
[GiveWell](https://www.givewell.org/)
https://www.thelifeyoucansave.org/
https://ea-foundation.org/
https://animalcharityevaluators.org

# 12th September
Data pulls were previously only pulling the effective charities, this has been changed now.

We also give a broader list in the file effective_charities_plus, including some additional international mega-charities like MSF.

## 'Post-covid' project

TODO: briefly reference/document the adjusted pull for this specific project, what is done where, etc. 
We recently pulled 9999 entries (the max) per charity for each of the top-10 UK charities as well as the effective charities. 



