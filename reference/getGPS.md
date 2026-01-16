# Get GPS variables

To improve speed, the `alltags` view doesn't include GPS-related
variables such as `gpsLat`, `gpsLon`, or `gpsAlt`. There is a
`alltagsGPS` view that does include GPS-related variables, but this will
take time to load. This function accepts a source and returns the GPS
data associated with the `hitID`s in the `alltags` view. Optionally,
users can supply a subset of the `alltags` view to return only GPS data
associated with the specific `hitID`s present in the subset.

## Usage

``` r
getGPS(src, data = NULL, by = "daily", cutoff = NULL, keepAll = FALSE)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- data:

  SQLite connection or data.frame. Optional subset of the `alltags`
  view. Must have `ts`, `batchID` and `hitID` at the minimum.

- by:

  Numeric/Character. Either the time in minutes over which to join GPS
  locations to hits, or "daily" or "closest". To join GPS locations by
  daily time blocks or by the closest temporal match (see Details).

- cutoff:

  Numeric. The maximum allowable time in minutes between hit and GPS
  timestamps when matching hits to GPS with `by = 'closest'`. Defaults
  to `NULL` (no maximum).

- keepAll:

  Logical. Return all hits regardless of whether they have a GPS match?
  Defaults to FALSE.

## Value

Data frame linking hitID to gpsLat, gpsLon and gpsAlt. When
`by = 'daily'` or `by = 'X'`, output includes:

- `hitID` - the ID associated with the hit

- `gpsLat` \\ `gpsLon` \\ `gpsAlt` - the median location calculated from
  the available GPS points

- `gpsTs_min` \\ `gps_Ts_max` - the range of GPS timestamps associated
  with the GPS points binned

When `by = 'closest'` or `by = 'X'`, output includes:

- `hitID` - the ID associated with the hit

- `gpsID` - the ID of the closest GPS point aligned with the `hitID`

- `gpsLat` \\ `gpsLon` \\ `gpsAlt` - the location of the GPS point

- `gpsTs` - the timestamp of the GPS point

## Details

There are three different methods for matching GPS data to `hitID`s all
related to timestamps (`ts`).

1.  `by = X` Where `X` is a duration in minutes. `ts` is converted to a
    specific time block of duration `X`. Median GPS lat/longs for the
    time block are returned, matching associated `hitID` time blocks.

2.  `by = "daily"` (the default). Similar to `by = X` except the
    duration is 24hr.

3.  `by = "closest"` Individual GPS lat/lons are returned, matching the
    closest `hitID` timestamp. Use `cutoff` to specify the maximum
    allowable time between timestamps (defaults to none).

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# Match hits to GPS within 24hrs (daily) of each other
my_gps <- getGPS(sql_motus)
my_gps
#> [1] hitID  gpsTs  gpsLat gpsLon gpsAlt
#> <0 rows> (or 0-length row.names)

# Note that the sample data doesn't have GPS hits so this will be an 
# empty data frame for project 176.

# Match hits to GPS within 15min of each other
my_gps <- getGPS(sql_motus, by = 15)
my_gps
#> [1] hitID  gpsTs  gpsLat gpsLon gpsAlt
#> <0 rows> (or 0-length row.names)

# Match hits to GPS according to the closest timestamp
my_gps <- getGPS(sql_motus, by = "closest")
my_gps
#> [1] hitID  gpsTs  gpsLat gpsLon gpsAlt
#> <0 rows> (or 0-length row.names)

# Match hits to GPS according to the closest timestamp, but limit to within
# 20min of each other
my_gps <- getGPS(sql_motus, by = "closest", cutoff = 20)
my_gps
#> [1] hitID  gpsTs  gpsLat gpsLon gpsAlt
#> <0 rows> (or 0-length row.names)

# To return all hits, regardless of whether they match a GPS record

my_gps <- getGPS(sql_motus, keepAll = TRUE)
my_gps
#> # A tibble: 109,474 × 4
#>      hitID gpsLat gpsLon gpsAlt
#>    <int64>  <dbl>  <dbl>  <dbl>
#>  1   45107     NA     NA     NA
#>  2   45108     NA     NA     NA
#>  3   45109     NA     NA     NA
#>  4   45110     NA     NA     NA
#>  5   45111     NA     NA     NA
#>  6  199885     NA     NA     NA
#>  7  199886     NA     NA     NA
#>  8  199887     NA     NA     NA
#>  9  199888     NA     NA     NA
#> 10  199889     NA     NA     NA
#> # ℹ 109,464 more rows

# Alternatively, use the alltagsGPS view:
dplyr::tbl(sql_motus, "alltagsGPS")
#> # Source:   table<`alltagsGPS`> [?? x 65]
#> # Database: sqlite 3.51.1 [:memory:]
#>     hitID runID batchID      ts tsCorrected   sig sigsd noise  freq freqsd  slop
#>     <int> <int>   <int>   <dbl>       <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
#>  1  45107  8886      53  1.45e9 1445858390.    52     0   -96     4      0  1e-4
#>  2  45108  8886      53  1.45e9 1445858429.    54     0   -96     4      0  1e-4
#>  3  45109  8886      53  1.45e9 1445858477.    55     0   -96     4      0  1e-4
#>  4  45110  8886      53  1.45e9 1445858516.    52     0   -96     4      0  1e-4
#>  5  45111  8886      53  1.45e9 1445858564.    49     0   -96     4      0  1e-4
#>  6 199885 23305      64  1.45e9 1445857924.    33     0   -96     4      0  1e-4
#>  7 199886 23305      64  1.45e9 1445857983.    41     0   -96     4      0  1e-4
#>  8 199887 23305      64  1.45e9 1445858041.    29     0   -96     4      0  1e-4
#>  9 199888 23305      64  1.45e9 1445858089.    41     0   -96     4      0  1e-4
#> 10 199889 23305      64  1.45e9 1445858147.    45     0   -96     4      0  1e-4
#> # ℹ more rows
#> # ℹ 54 more variables: burstSlop <dbl>, done <int>, motusTagID <int>,
#> #   ambigID <int>, port <chr>, nodeNum <chr>, runLen <int>, motusFilter <dbl>,
#> #   bootnum <int>, tagProjID <int>, mfgID <chr>, tagType <chr>, codeSet <chr>,
#> #   mfg <chr>, tagModel <chr>, tagLifespan <int>, nomFreq <dbl>, tagBI <dbl>,
#> #   pulseLen <dbl>, tagDeployID <int>, speciesID <int>, markerNumber <chr>,
#> #   markerType <chr>, tagDeployStart <dbl>, tagDeployEnd <dbl>, …
```
