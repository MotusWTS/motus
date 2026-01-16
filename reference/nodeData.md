# Add/update nodeData

Download or resume a download of the 'nodeData' table in an existing
Motus database. `nodeData` contains information regarding the 'health'
of portable node units.

## Usage

``` r
nodeData(src, resume = FALSE)
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

If an `nodeData` table doesn't exist, it will be created prior to
downloading. If there is an existing `nodeData` table, this will update
the records.

Note that only records for CTT tags will have the possibility of
`nodeData`.

Node metadata is found in the `nodeDeps` table, updated along with other
metadata.

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()
  
# Access `nodeData` table
library(dplyr)
a <- tbl(sql_motus, "nodeData")
  
# If you just want to download `nodeData`
if (FALSE) my_tags <- nodeData(sql_motus) # \dontrun{}
```
