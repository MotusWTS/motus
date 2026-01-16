# General summary of detections for each tag

Creates a summary for each tag of it's first and last detection time
(`ts`), first and last detection site, length of time between first and
last detection, straight line distance between first and last detection
site, rate of movement, and bearing. Lat/lons are taken from
`gpsLat`/`gpsLon`, or if missing, from `recvDeployLat`/`recvDeployLon`.
Bearing is calculated using the
[`geosphere::bearing()`](https://rdrr.io/pkg/geosphere/man/bearing.html)
function.

## Usage

``` r
tagSum(df_src, data)
```

## Arguments

- df_src:

  Data frame, SQLite connection, or SQLite table. An SQLite connection
  would be the result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`; an SQLite table
  would be the result of `dplyr::tbl(tags, "alltags")`; a data frame
  could be the result of
  `dplyr::tbl(tags, "alltags") %>% dplyr::collect()`.

- data:

  Defunct, use `src`, `df_src`, or `df` instead.

## Value

A flat data frame with the following for each tag:

- `fullID` - `fullID` of Motus registered tag

- `first_ts` - Time (`ts`) of first detection

- `last_ts` - Time (`ts`) of last detection

- `first_site` - First detection site (`recvDeployName`)

- `last_site` - Last detection site (`recvDeployName`)

- `recvLat.x` - Latitude of first detection site (`gpsLat` or
  `recvDeployLat`)

- `recvLon.x` - Longitude of first detection site (`gpsLon` or
  `recvDeployLon`)

- `recvLat.y` - Latitude of last detection site (`gpsLat` or
  `recvDeployLat`)

- `recvLon.y` - Longitude of last detection site (`gpsLon` or
  `recvDeployLon`)

- `tot_ts` - Time between first and last detection (in seconds)

- `dist` - Straight line distance between first and last detection site
  (in metres)

- `rate` - Overall rate of movement (`tot_ts`/`dist`), in metres/second

- `bearing` - Bearing between first and last detection sites

- `num_det` - Number of detections summarized

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# Summarize tags
tag_summary <- tagSum(sql_motus)
#> 'df_src' is a complete motus data base, using 'alltagsGPS' view

# For specific SQLite table/view (needs gpsLat/gpsLon) --------------
library(dplyr)
tbl_alltagsGPS <- tbl(sql_motus, "alltagsGPS") 
tag_summary <- tagSum(tbl_alltagsGPS)

# For a flattened data frame ----------------------------------------
df_alltagsGPS <- collect(tbl_alltagsGPS)
tag_summary <- tagSum(df_alltagsGPS)

# Can be filtered, e.g., for only a few tags
tag_summary <- tagSum(filter(tbl_alltagsGPS, motusTagID %in% c(16047, 16037, 16039)))
```
