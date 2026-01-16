# Create a dataframe of simultaneous detections at multiple sites

Creates a dataframe consisting of detections of tags that are detected
at two or more receiver at the same time.

## Usage

``` r
simSiteDet(data)
```

## Arguments

- data:

  a selected table from .motus data, eg. "alltags", or a data.frame of
  detection data including at a minimum variables for `motusTagID`,
  `recvDeployName`, `ts`

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# convert sql file "sql_motus" to a tbl called "tbl_alltags"
library(dplyr)
tbl_alltags <- tbl(sql_motus, "alltags") 

# convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
df_alltags <- tbl_alltags %>% 
  collect() %>% 
  as.data.frame()

# To get a data.frame of just simultaneous detections from a tbl file
# tbl_alltags
simSites <- simSiteDet(tbl_alltags)

# To get a data.frame of just simultaneous detections from a dataframe
# df_alltags
simSites <- simSiteDet(df_alltags)
```
