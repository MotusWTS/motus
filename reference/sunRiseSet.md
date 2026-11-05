# Obtain sunrise and sunset times

Create and add sunrise and sunset columns to tag data. Can take a motus
database table, but will always return a collected data frame. Requires
data containing at least latitude, longitude, and time.

## Usage

``` r
sunRiseSet(
  df_src,
  lat = "recvDeployLat",
  lon = "recvDeployLon",
  ts = "ts",
  data
)
```

## Arguments

- df_src:

  Data frame, SQLite connection, or SQLite table. An SQLite connection
  would be the result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`; an SQLite table
  would be the result of `dplyr::tbl(tags, "alltags")`; a data frame
  could be the result of
  `dplyr::tbl(tags, "alltags") %>% dplyr::collect()`.

- lat:

  Character. Name of column with latitude values, defaults to
  `recvDeployLat`.

- lon:

  Character. Name of column with longitude values, defaults to
  `recvDeployLon`.

- ts:

  Character. Name of column with timestamp values, defaults to `ts`.

- data:

  Defunct, use `src`, `df_src`, or `df` instead.

## Value

Original data (as a flat data frame), with the following additional
columns:

- `sunrise` - Time of sunrise in **UTC** for that row's date and
  location

- `sunset` - Time of sunset in **UTC** for that row's date and location

## Details

Note that this will always return the sunrise and sunset of the *local*
date. For example, 2023-01-01 04:00:00 in Central North American time is
2023-01-01 in UTC, but 2023-01-01 20:00:00 is actually the following
date in UTC. Because Motus timestamps are UTC, times are first converted
to their local time zone time using the lat/lon coordinates before
extracting the date. Thus:

- A UTC timestamp of 1672624800 for Winnipeg, Canada is 2023-01-02
  02:00:00 UTC and 2023-01-01 20:00:00 local time

- Therefore `sunRiseSet()` calculates the sunrise/sunset times for
  2023-01-01 (not for 2023-01-02)

- These sunrise/sunset times are returned in UTC: 2023-01-01 14:27:50
  UTC and 2023-01-01 22:38:30 UTC

- Note that the UTC timestamp 2023-01-02 02:00:00 is later than the
  sunset time of 2023-01-01 22:38:30 UTC. This makes sense, as we know
  that the timestamp is ~8pm local time, well after sunset in the winter
  for that date.

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# For SQLite Data base-----------------------------------------------
sun <- sunRiseSet(sql_motus)
#> 'df_src' is a complete motus data base, using 'alltags' view

# For specific SQLite table/view ------------------------------------
library(dplyr)
tbl_alltagsGPS <- tbl(sql_motus, "alltagsGPS") 
sun <- sunRiseSet(tbl_alltagsGPS)

# For a flattened data frame ----------------------------------------
df_alltagsGPS <- collect(tbl_alltagsGPS)
sun <- sunRiseSet(df_alltagsGPS)

# Using alternate lat/lons ------------------------------------------
# Get sunrise and sunset information from tbl_alltags using gps lat/lon
# Note this will only work if there are non-NA values in gpsLat/gpsLon
if (FALSE) sun <- sunRiseSet(tbl_alltagsGPS, lat = "gpsLat", lon = "gpsLon") # \dontrun{}
```
