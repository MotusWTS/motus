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

- `main` branch - Current release - e.g., v4.0.3
- `betaX` branch - Current minor dev - e.g., v4.0.3.9000
- `sandbox` branch - Current major dev - e.g., v4.0.3.9999
- `dev`/`hotfix-` branch - Current quick fixes to merge in to main quickly v4.0.3.9001 (increments one greater than `betaX`)


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
- Querying and changing the data base is done with wrapper functions: `DBI_Query()`
  and `DBI_Execute()` in `utils-wrappers.R`. These use `glue_sql()` to combine
  statements and insert parameters. Note the use of backticks {`var`} when 
  inserting table or column names into a statement.

## Talk to the API - Boxing/Unboxing JSON parameters
- The API requires that some parameters be boxed (i.e. `[parameter]`) and some
be unboxed (i.e., `parameter`)
- In `srvQuery.R`, `jsonlite::toJSON()` unboxes all single value parameters
- If you have a parameter that should NOT be unboxed
  (usually a single value parameter that could have more), you must go to its
  `srvXXXX.R` file, and add `I(parameter)` (e.g., `srvTagsForAmbiguities.R`)
- However, `I()` won't work on `NULL` values, so we need to get creative
  if it can have either NULL or values (e.g., `srvTagMetadataForProjects.R`)
- Potentially worth rethinking whether to force boxing via class/type
  BEFORE gets sent as a parameter...


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
- Source `data-raw/internal_data.R`, this will run `data-raw/field_names.R` which
  should grab the new field name from the server and add it to the list of tables
    - If there's a special SQL command, however, you'll have add that by hand to the 
    table in `data-raw/field_names.R`
- Add update to `data-raw/updatesql.R` (run script, re-build package locally)
- Add test to make sure new field is added (`tests/testthat/test_02_sqlite.R`)
  and filled with data (`tests/testthat/test_07_data_returned.R`)
- Update internal data `source("data-raw/sample_data.R")`
- Update NEWS.md
- Run tests
- Push!

### Adding a new table
- Add a section to `data-raw/field_names.R` pulling the new table data from the
  server and adding it to the list of tables
- In `ensureDBTables.R` either add it to the list of tables that are created 
  empty, or add it to the section where tables are created and then immediately
  filled with data (and add the data that should fill it). 
- If the table has `batchIDs` add it to the list of tables in which to remove
  deprecated `batchIDs` in `deprecateBatches()` in the `deprecateBatches.R` file.
- You **shouldn't** need to add a section to `data-raw/updatesql.R`
- Add test to make sure new field is added (`tests/testthat/test_02_sqlite.R`)
  and filled with data (`tests/testthat/test_07_data_returned.R`)
- Update internal data `source("data-raw/sample_data.R")`
- Update NEWS.md
- Push!