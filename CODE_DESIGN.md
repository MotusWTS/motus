# motus design principles

This is a collection of developer notes and is by no means exhaustive or correct

- [Versioning](#versioning)
- [Naming Conventions](#naming-conventions)
- [SQLite databases](#sqlite-databases)
- [Special data downloads](#special-data-downloads)
- [Special Files](#special-files)
- [Data Files](#data-files)
- [Testing](#testing)
- [Adding and Updating](#adding-and-updating)

## Versioning
There 3-4 different `motus` versions on GitHub at any one time:

- `master` branch - Current release - e.g., v4.0.3
- `betaX` branch - Current minor dev - e.g., v4.0.3.9000
- `sandbox` branch - Current major dev - e.g., v4.0.3.9999
- `hotfix-` branch - Current quick fixes to merge in to master quickly v4.0.3.9001 (increments one greater than `betaX`)


## Naming Conventions
- Each function in a single file
- Exceptions
    - `utils.R` contains internal utility functions
    - `ensureDBTables.R` also contains `makeTable()` function to create tables
    - `updateMotusDb.R` also contains `checkViews()` function to check for custom views
    
## SQLite databases
- Empty SQLite tables created
- `ensureDBTables()` checks for existing tables and creates empty tables if they 
  don't exist
    - some tables are created with `makeTables()`
- When changing the data base, the `checkVersion()` function compares the date 
  in the `admInfo` table to the date in the internal data frame `sql_versions`
    - `sql_versions` is created in `./data-raw/updatesql.R`
- If the database is out of date, `checkVersion()` applies the SQLite commands
  in the `sql_version` data frame to update the data base
- Sometimes this involves making a temporary copy of a table, re-creating (with 
  changes) the original table and then copying the data back. In these cases the
  table structure is created by the `makeTables()` function (so it can be used by 
  `updatesql.R` as well as by `ensureDBTables()` without duplicating the process. 
- `checkDataVersion()` is used to update data versions (not database versions)

## Special data downloads
- Data that is downloaded by `batchID` after the main runs download
- `pageDataByBatch()` is a function that sets up the process
- `activity()` and `nodeData()` set the functions used to get going, but all is 
  passed to `pageDataByBatch()` as the workhorse function

## Special Files
- `z.onLoad.R`
  - Set session variables (i.e., API links) and motus options 
    (i.e. max batches to get when testing)
- `Motus.R` - Define empty session variable (filled with `z.onLoad.R`)
- `motus-pkg.R` - Help file documentation for the motus package

## Data Files
- Sample data for examples and testing, created in `./data-raw/sample_data.R`
  - INCOMPLETE
- `updatesql.R`

## Testing
- `sample_auth()` is used for automatic tests involving the motus.sample project
  176
- `local_auth()` is used to load locally stored credentials for private projects 
  to test local functionality 
- `skip_if_not_auth()` is used in tests to a) implement local authorizations if
  present and b) skip the test if they are not present

`motusUpdateTagDB()` and `pageDataByBatch()` have checks in them that will halt 
a download after `getOption("motus.test.max")` batches IF in a testing 
environment. This way testing can be done much more quickly on a variety of
projects/receivers.

- `is_testing()` is an internal function that checks if a test is being run
- `set_testing()` is an internal function for declaring that testing is being performed (for interactive testing, use `set_testing()` to start and `set_testing(set = FALSE)` to stop)

## Adding and Updating

### Adding a new field/column
- Make change to `ensureDBTables()`
- Add update to `data-raw/updatesql.R` (run script, re-build package locally)
- Add test to make sure new field is added (test_sqlite and test_data_returned)
- Update internal data `source("data-raw/sample_data.R")`
- Update NEWS.md
- Push!




