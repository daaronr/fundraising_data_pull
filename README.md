# FORK of Toby's original code to interact with the JustGiving API

I (@daaronr) have adjusted it slightly (see commits) and I am using this to do data pulls and capture data used elsewhere.

# Charity seeding experiment code and process

## How do I make the code run?

DR: First you need to register and create an app id on JustGiving, and save this as in a file you call
a file "my_app_id.R", containing a single line of text
```
my_app_id <- "/[ID]"
```
replacing "[ID]" with your ID, without the brackets.

Next...

The charities that this script uses (in effective_charities.csv) are all recommended by one or more organisations associated with effective altruism:
https://www.givewell.org/
https://www.thelifeyoucansave.org/
https://ea-foundation.org/
https://animalcharityevaluators.org/

Install the packages at the top of main.R.
Open
```
fundraising_data_pull.Rproj
```
using R and run main.R .
It will take 30 - 60 minutes to download all the data; this appears to be determined by Just Giving API limits.

## What are the files created?
2 files are created (?and 4 are updated) each time data is drawn from the API, and these are stored to the folders mentioned below.

Note that we must run this regularly to retain data from expired pages (which can't be accessed through the api).

*DR: The above needs clarification. The 'all_' files are no longer being created I think*

The charities that this script uses (in effective_charities.csv) are all recommended by one or more organisations associated with effective altruism (although in some cases the lists only recommend targeting a particular part of the charity's work) [and see comment below].

(Note: we also give a broader list in the file effective_charities_plus, including some additional international mega-charities like MSF.)

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
**data_pulls.csv** is updated after every pull with the date and the file paths of the 2 files created (fundraisers and donations). The most recent files referenced in this table are used to update the other files.

Note: additional details for our project [moved to private page](https://github.com/daaronr/sponsorship_design_analysis/tree/master/preregistration_plans_notes)

my_app_id <- {/your app id}

#You may need to add quotes around this, i.e., my_app_id <- "/id_number"

