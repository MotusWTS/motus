# Plots number of detections and tags, daily, for a specified site

Plots total number of detections across all tags, and total number of
tags detected per day for a specified site. Depends on
[`siteSumDaily()`](https://motuswts.github.io/motus/reference/siteSumDaily.md).

## Usage

``` r
plotDailySiteSum(data, recvDeployName)
```

## Arguments

- data:

  a selected table from .motus data, eg. "alltagsGPS", or a data.frame
  of detection data including at a minimum variables for `motusTagID`,
  `sig`, `recvDeployName`, `ts`

- recvDeployName:

  name of site to plot

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# convert sql file "sql_motus" to a tbl called "tbl_alltags"
library(dplyr)
tbl_alltags <- tbl(sql_motus, "alltagsGPS") 

# convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
df_alltags <- tbl_alltags %>% 
  collect() %>% 
  as.data.frame() 

# Plot of all tag detections at site Longridge using dataframe df_alltags
plotDailySiteSum(df_alltags, recvDeployName = "Longridge")


# Plot of all tag detections at site Niapiskau using tbl file tbl_alltags
plotDailySiteSum(df_alltags, recvDeployName = "Niapiskau")
```
