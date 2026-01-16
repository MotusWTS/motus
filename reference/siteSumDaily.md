# Summarize daily detections of all tags by site

Creates a summary of the first and last daily detection at a site, the
length of time between first and last detection, the number of tags, and
the total number of detections at a site for each day. Same as
[`siteSum()`](https://motuswts.github.io/motus/reference/siteSum.md),
but daily by site.

## Usage

``` r
siteSumDaily(data, units = "hours")
```

## Arguments

- data:

  a selected table from .motus data, eg. "alltagsGPS", or a data.frame
  of detection data including at a minimum variables for `motusTagID`,
  `sig`, `recvDeployName`, `ts`

- units:

  units to display time difference, defaults to "hours", options include
  "secs", "mins", "hours", "days", "weeks"

## Value

a data.frame with these columns:

- recvDeployName: site name of deployment

- date: date that is being summarized

- first_ts: time of first detection on specified "date" at
  "recvDeployName"

- last_ts: time of last detection on specified "date" at
  "recvDeployName"

- tot_ts: total amount of time between first and last detection at
  "recvDeployName" on "date, output in specified unit (defaults to
  "hours")

- num.tags: total number of unique tags detected at "recvDeployName", on
  "date"

- num.det: total number of detections at "recvDeployName", on "date"

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

# Create site summaries for all sites within detection data with time in
# minutes using tbl file tbl_alltags
daily_site_summary <- siteSumDaily(tbl_alltags, units = "mins")

# Create site summaries for only select sites with time in minutes using tbl
# file tbl_alltags
sub <- filter(tbl_alltags, recvDeployName %in% c("Niapiskau", "Netitishi", 
                                                 "Old Cut", "Washkaugou"))
daily_site_summary <- siteSumDaily(sub, units = "mins")

# Create site summaries for only a select species, Red Knot, with default
# time in hours using data frame df_alltags
daily_site_summary <- siteSumDaily(filter(df_alltags,
                                          speciesEN == "Red Knot"))
```
