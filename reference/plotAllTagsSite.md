# Plot all tag detections by deployment

Plot deployment (ordered by latitude) vs time (UTC) for each tag

## Usage

``` r
plotAllTagsSite(data, coordinate = "recvDeployLat", tagsPerPanel = 5)
```

## Arguments

- data:

  a selected table from .motus data, eg. "alltags", or a data.frame of
  detection data including at a minimum variables for `recvDeployName`,
  `fullID`, `mfgID`, date/time, `latitude` or `longitude`

- coordinate:

  column of receiver latitude/longitude values to use, defaults to
  `recvDeployLat`

- tagsPerPanel:

  number of tags in each panel of the plot, default is 5

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

# Plot detections of dataframe df_alltags by site ordered by latitude, with
# default 5 tags per panel
plotAllTagsSite(df_alltags)


# Plot detections of dataframe df_alltags by site ordered by latitude, with
# 10 tags per panel
plotAllTagsSite(df_alltags, tagsPerPanel = 10)


# Plot detections of tbl file tbl_alltags by site ordered by receiver
# deployment latitude
plotAllTagsSite(tbl_alltags, coordinate = "recvDeployLon")


# Plot tbl file tbl_alltags using 3 tags per panel for species Red Knot
plotAllTagsSite(filter(tbl_alltags, speciesEN == "Red Knot"), tagsPerPanel = 3)
```
