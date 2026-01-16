# Add/update all batch activity

Download or resume a download of the `activityAll` table in an existing
Motus database. Batch activity refers to the number of hits detected
during a given batch. Batches with large numbers of hits may indicate
interference and thus unreliable hits.

## Usage

``` r
activityAll(src, resume = FALSE)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- resume:

  Logical. Resume a download? Otherwise the table is removed and the
  download is started from the beginning.

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()
  
# Get all activity
if (FALSE) sql_motus <- activityAll(sql_motus) # \dontrun{}

# Access 'activityAll' table
library(dplyr)
a <- tbl(sql_motus, "activityAll")
  
# If interrupted and you want to resume
if (FALSE) sql_motus <- activityAll(sql_motus, resume = TRUE) # \dontrun{}
```
