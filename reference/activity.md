# Add/update batch activity

Download or resume a download of the `activity` table in an existing
Motus database. Batch activity refers to the number of hits detected
during a given batch. Batches with large numbers of hits may indicate
interference and thus unreliable hits.

## Usage

``` r
activity(src, resume = FALSE)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- resume:

  Logical. Resume a download? Otherwise the table is removed and the
  download is started from the beginning.

## Details

This function is automatically run by the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function with `resume = TRUE`.

If an `activity` table doesn't exist, it will be created prior to
downloading. If there is an existing `activity` table, this will update
the records.

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()
   
# Access 'activity' table
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
a <- tbl(sql_motus, "activity")
  
# If interrupted and you want to resume
if (FALSE) my_tags <- activity(sql_motus, resume = TRUE) # \dontrun{}
```
