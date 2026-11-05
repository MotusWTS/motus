# Obtain time to and from sunrise/sunset

Create and add columns for time to and time since sunrise/sunset to tag
data. Can take a motus database table, but will always return a
collected data frame. Requires data containing at least latitude,
longitude, and time.

## Usage

``` r
timeToSunriset(
  df_src,
  lat = "recvDeployLat",
  lon = "recvDeployLon",
  ts = "ts",
  units = "hours",
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
  `recvDeployLat`

- lon:

  Character. Name of column with longitude values, defaults to
  `recvDeployLon`

- ts:

  Character. Name of column with time as numeric or POSIXct, defaults to
  `ts`

- units:

  Character. Units to display time difference, defaults to "hours",
  options include "secs", "mins", "hours", "days", "weeks".

- data:

  Defunct, use `src`, `df_src`, or `df` instead.

## Value

Original data (as a flat data frame), with the following additional
columns:

- `sunrise` - Time of sunrise in **UTC** for that row's date and
  location

- `sunset` - Time of sunset in **UTC** for that row's date and location

- `ts_to_set` - Time to next sunset, in `units`

- `ts_since_set` - Time to previous sunset, in `units`

- `ts_to_rise` - Time to next sunrise after, in `units`

- `ts_since_rise` - Time to previous sunrise, in `units`

## Details

Uses
[`sunRiseSet()`](https://motuswts.github.io/motus/reference/sunRiseSet.md)
to perform sunrise/sunset calculates, see
[`?sunRiseSet`](https://motuswts.github.io/motus/reference/sunRiseSet.md)
for details regarding how local dates are assessed from UTC timestamps.

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# Get sunrise and sunset information for alltags view with units in minutes
sunrise <- timeToSunriset(sql_motus, units = "mins")
#> 'df_src' is a complete motus data base, using 'alltags' view
```
