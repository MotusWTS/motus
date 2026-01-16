# Fetch and remove deprecated batches

Deprecated batches are removed from the online database but not from
local data files. This function fetches a list of deprecated batches
(stored in the 'deprecated' table), and, optionally, removes these
batches from all tables that reference `batchID`s

## Usage

``` r
deprecateBatches(src, fetchOnly = FALSE, ask = TRUE)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- fetchOnly:

  Logical. Only *fetch* batches that are deprecated. Don't remove
  deprecated batches from other tables.

- ask:

  Logical. Ask for confirmation when removing deprecated batches

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) { # \dontrun{
sql_motus <- tagme(176, new = TRUE)
  
# Access 'deprecated' table using tbl() from dplyr
library(dplyr)
tbl(sql_motus, "deprecated")

# See that there are deprecated batches in the data
filter(tbl(sql_motus, "alltags"), batchID == 6000)

# Fetch deprecated batches
deprecateBatches(sql_motus, fetchOnly = TRUE)

# Remove deprecated batches (will ask for confirmation unless ask = FALSE)
deprecateBatches(sql_motus, ask = FALSE)

# See that there are NO more deprecated batches in the data
filter(tbl(sql_motus, "alltags"), batchID == 6000)
} # }
```
