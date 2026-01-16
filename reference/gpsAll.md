# Add/update all GPS points

Download or resume a download of the `gpsAll` table in an existing Motus
database. Batch activity refers to the number of hits detected during a
given batch. Batches with large numbers of hits may indicate
interference and thus unreliable hits.

## Usage

``` r
gpsAll(src, resume = TRUE)
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
  
# Get all GPS points
if (FALSE) sql_motus <- gpsAll(sql_motus) # \dontrun{}

# Access 'gpsAll' table
library(dplyr)
g <- tbl(sql_motus, "gpsAll")
  
# gpsAll resumes a previous download by default
# If you want to delete this original data and do a fresh download, 
# use resume = FALSE
if (FALSE) sql_motus <- gpsAll(sql_motus, resume = FALSE) # \dontrun{}
```
