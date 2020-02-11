# employee database

This repository demonstrates an employee database that is used to track changes to a team and enable reporting. The queries in this example are based on Google's BigQuery.

Google Sheets Apps Script is used to access views of the database as well as make updates to the database

## directories

This project is organized as follows:
- **create_tables** contains SQL queries for creating empty tables
- **load_samples** contains SQL queries for loading sample data
- **updates** contains SQL queries for updating the database
- **views** contains SQL queries for accessing views of the database
- **google_apps_script** contains Apps Script used to integrate with Google Sheets

## notes
- Apps Script logging can be found here https://script.google.com/home
- BigQuery Apps Script documentation can be found here https://developers.google.com/apps-script/advanced/bigquery 

## progress
- Created tables and loaded sample data
- Views for current team, former employees, hierarchy, reporting
- Scripts for adding new employees, deleting employees, updating employees
- Google Sheets integration with views (Apps Script)
- Google Sheets upload to BigQuery for add employees (Apps Script)

## to do
- update add employees Apps Script to clear sheet after uploading
- delete staging table upon successful insert to production table
- add Google Sheets Apps Script for changing team members (e.g. new hires, promotions, exits)

## known issues
- `former_employees.sql` gives duplicates when there are multiple team member changes on the most recent date (joined on the maximum last change date)
- currently able to load an entire sheet to BigQuery but getting errors when trying to load a limited range of cells