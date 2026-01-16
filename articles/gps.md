# Working with GPS points

Some tags also collect GPS points, which can be used for more precise
locations (as opposed to the receiver location
`recDeployLat`/`recDeployLon`). In this article we will show you how to
efficiently work with these GPS points.

First, let’s get set up. The motus.sample data (project 176) doesn’t
have GPS points, so in these next examples we’ll be using a different
data base called `gps_tags`.

``` r
library(motus)
library(tidyverse)
library(lubridate)

gps_tags
```

    ## <SQLiteConnection>
    ##   Path: /home/runner/work/motus/motus/vignettes/articles/data/gps_sample.motus
    ##   Extensions: TRUE

If your data has gps point, you should be able to follow along using
your own data (replace `PROJECT_NUMBER` with the number corresponding to
your project.

``` r
gps_tags <- tagme(PROJECT_NUMBER, new = TRUE)
```

GPS points are stored in the `gps` table.

``` r
tbl(gps_tags, "gps")
```

    ## # Source:   table<`gps`> [?? x 11]
    ## # Database: sqlite 3.51.1 [/home/runner/work/motus/motus/vignettes/articles/data/gps_sample.motus]
    ##      gpsID batchID        ts gpsts   lat    lon    alt quality lat_mean lon_mean
    ##      <int>   <int>     <dbl> <dbl> <dbl>  <dbl>  <dbl>   <int>    <dbl>    <dbl>
    ##  1  313414  127792    1.51e9    NA  33.5 -104.  1074        NA       NA       NA
    ##  2  313415  127792    1.51e9    NA  33.5 -104.  1072.       NA       NA       NA
    ##  3 4967619  370452    1.46e9    NA  36.5  -76.0   -3.4      NA       NA       NA
    ##  4 4967620  370452    1.46e9    NA  36.5  -76.0    8.7      NA       NA       NA
    ##  5 4967621  370452    1.46e9    NA  36.5  -76.0    5.3      NA       NA       NA
    ##  6 4967622  370452    1.46e9    NA  36.5  -76.0   -6.6      NA       NA       NA
    ##  7 4967623  370452    1.46e9    NA  36.5  -76.0   -3.1      NA       NA       NA
    ##  8 4967624  370452    1.46e9    NA  36.5  -76.0    2.5      NA       NA       NA
    ##  9 4967625  370452    1.46e9    NA  36.5  -76.0   -4.8      NA       NA       NA
    ## 10 4967626  370452    1.46e9    NA  36.5  -76.0    1        NA       NA       NA
    ## # ℹ more rows
    ## # ℹ 1 more variable: n_fixes <int>

## Working with GPS points

You can work with GPS points in one of two ways:

1.  For small data bases - Use the `alltagsGPS` view directly (can be
    slow)
2.  For large data bases - Filter first, then use the `addGPS()`
    function to match GPS points to your hits

### `alltagsGPS` view

The `alltagsGPS` view combines hits and GPS points

``` r
tbl(gps_tags, "alltagsGPS") %>%
  select(hitID, runID, batchID, ts, gpsLat, gpsLon, gpsAlt)
```

    ## # Source:   SQL [?? x 7]
    ## # Database: sqlite 3.51.1 [/home/runner/work/motus/motus/vignettes/articles/data/gps_sample.motus]
    ##       hitID   runID batchID          ts gpsLat gpsLon gpsAlt
    ##       <int>   <int>   <int>       <dbl>  <dbl>  <dbl>  <dbl>
    ##  1 32811108 7984227  118721 1509139743.     NA     NA     NA
    ##  2 32811109 7984227  118721 1509139823.     NA     NA     NA
    ##  3 32912898 7985620  120474 1515877560.     NA     NA     NA
    ##  4 32912899 7985620  120474 1515877600.     NA     NA     NA
    ##  5 32913271 7985787  120474 1515878154.     NA     NA     NA
    ##  6 32913272 7985787  120474 1515878194.     NA     NA     NA
    ##  7 32913404 7985850  120474 1515878250.     NA     NA     NA
    ##  8 32913405 7985850  120474 1515878329.     NA     NA     NA
    ##  9 32913717 7985998  120474 1515878623.     NA     NA     NA
    ## 10 32913718 7985998  120474 1515878662.     NA     NA     NA
    ## # ℹ more rows

Note that not all hits have a GPS point associated, but we can filter to
those that do:

``` r
tbl(gps_tags, "alltagsGPS") %>%
  select(hitID, runID, batchID, ts, gpsLat, gpsLon, gpsAlt) %>%
  filter(!is.na(gpsLat))
```

    ## # Source:   SQL [?? x 7]
    ## # Database: sqlite 3.51.1 [/home/runner/work/motus/motus/vignettes/articles/data/gps_sample.motus]
    ##        hitID    runID batchID          ts gpsLat gpsLon gpsAlt
    ##        <int>    <int>   <int>       <dbl>  <dbl>  <dbl>  <dbl>
    ##  1 449016552 24439773  370452 1457111891.   36.5  -76.0   -3.4
    ##  2 449016553 24439773  370452 1457111897.   36.5  -76.0   -3.4
    ##  3 449016554 24439773  370452 1457111904.   36.5  -76.0   -3.4
    ##  4 449016555 24439774  370452 1457111897.   36.5  -76.0   -3.4
    ##  5 449016556 24439774  370452 1457111904.   36.5  -76.0   -3.4
    ##  6 449016557 24439775  370452 1457111891.   36.5  -76.0   -3.4
    ##  7 449016558 24439775  370452 1457111910.   36.5  -76.0   -3.4
    ##  8 449016559 24439773  370452 1457111910.   36.5  -76.0   -3.4
    ##  9 449016560 24439774  370452 1457111916.   36.5  -76.0   -3.4
    ## 10 449016561 24439775  370452 1457111916.   36.5  -76.0   -3.4
    ## # ℹ more rows

> Note: The `alltagsGPS` view is the same as the `alltags` view but
> includes GPS points. Because of this, the `alltagsGPS` view can be
> slower to work with, particularly if you have a large database.

### Filtering then adding GPS data

For example, let’s work with a subset of the alltags view, including
only King Rails.

``` r
rails <- tbl(gps_tags, "alltags") %>%
  filter(speciesEN == "King Rail")
```

Now let’s retrieve the daily median location of GPS points for these
data. Note that we use both the original database `gps_tags` as well as
the data subset `rails`. Also note that the
[`getGPS()`](https://motuswts.github.io/motus/reference/getGPS.md)
function requires the original, numeric `ts` column, so if you want a
date/time column it’s best to rename it (i.e. `time = as_datetime(ts)`).

``` r
index_GPS <- getGPS(src = gps_tags, data = rails)
```

This table is an index matching GPS points to specific `hitID`, so the
next step is to join it into your data subset using the
[`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
function from the `dplyr` package. Note that at this point, we need to
use [`collect()`](https://dplyr.tidyverse.org/reference/compute.html) to
ensure that `rails` is ‘flat’ (i.e. a data frame, not a database; see
[Converting to flat
data](https://motuswts.github.io/motus/articles/03-accessing-data.html#converting-to-flat-data)
for more details).

``` r
rails_GPS <- left_join(collect(rails), index_GPS, by = "hitID")
```

We can subset the columns to see if it worked as expected (we filter to
non-missing, because not all hits have a GPS point when using the
default matching).

``` r
rails_GPS %>%
  select(hitID, runID, batchID, ts, contains("gps")) %>%
  filter(!is.na(gpsLat))
```

    ## # A tibble: 90 × 9
    ##         hitID    runID batchID       ts gpsLat gpsLon gpsAlt gpsTs_min gpsTs_max
    ##         <int>    <int>   <int>    <dbl>  <dbl>  <dbl>  <dbl>     <dbl>     <dbl>
    ##  1   34126729  8211543  127792   1.51e9   40.4  -76.1   106.    1.51e9    1.51e9
    ##  2   34126730  8211543  127792   1.51e9   40.4  -76.1   106.    1.51e9    1.51e9
    ##  3   34126795  8211576  127792   1.51e9   40.4  -76.1   106.    1.51e9    1.51e9
    ##  4   34126796  8211576  127792   1.51e9   40.4  -76.1   106.    1.51e9    1.51e9
    ##  5   34126846  8211593  127792   1.51e9   40.4  -76.1   106.    1.51e9    1.51e9
    ##  6   34126847  8211593  127792   1.51e9   40.4  -76.1   106.    1.51e9    1.51e9
    ##  7   34128916  8212308  132026   1.51e9   40.4  -76.1   105.    1.51e9    1.51e9
    ##  8   34128917  8212308  132026   1.51e9   40.4  -76.1   105.    1.51e9    1.51e9
    ##  9 1136575629 47145854  742386   1.50e9   44.0  -79.5   313.    1.50e9    1.50e9
    ## 10 1136575630 47145854  742386   1.50e9   44.0  -79.5   313.    1.50e9    1.50e9
    ## # ℹ 80 more rows

#### More ways of matching GPS points

By default,
[`getGPS()`](https://motuswts.github.io/motus/reference/getGPS.md)
matches GPS points to hits by date. However, we can match GPS locations
to `hitID`s according to one of several different time values, specified
by the `by` argument.

`by` can be one of three options:

1.  the median location within **`by = X`** minutes of a `hitID`
    - here, `X` can be any number greater than zero and represents the
      size of the time block in minutes over which to calculate a median
      location
    - be aware that you should ideally not chose a period smaller than
      the frequency at which GPS fixes are recorded, or some hits will
      not be associated with GPS

For example, the median location within 60 minutes of a `hitID`.

``` r
index_GPS <- getGPS(src = gps_tags, data = rails, by = 60)
index_GPS
```

    ## # A tibble: 78 × 6
    ##         hitID gpsLat gpsLon gpsAlt  gpsTs_min  gpsTs_max
    ##         <int>  <dbl>  <dbl>  <dbl>      <dbl>      <dbl>
    ##  1   34126729   40.4  -76.1   111. 1505761796 1505761796
    ##  2   34126730   40.4  -76.1   111. 1505761796 1505761796
    ##  3   34126795   40.4  -76.1   110. 1505776197 1505776197
    ##  4   34126796   40.4  -76.1   110. 1505776197 1505776197
    ##  5   34126846   40.4  -76.1   106. 1505837998 1505837998
    ##  6   34126847   40.4  -76.1   106. 1505837998 1505837998
    ##  7   34128916   40.4  -76.1   100. 1505350490 1505350490
    ##  8   34128917   40.4  -76.1   100. 1505350490 1505350490
    ##  9 1136575629   44.0  -79.5   312. 1496846031 1496846031
    ## 10 1136575630   44.0  -79.5   312. 1496846031 1496846031
    ## # ℹ 68 more rows

2.  **`by = "daily"`** median location (**default**, used in first
    example)
    - similar to `by = X` except the duration is 24hr (same as
      `by = 1440`)
    - this method is most suitable for receiver deployments at fixed
      location.

``` r
index_GPS <- getGPS(src = gps_tags, data = rails, by = "daily")
index_GPS
```

    ## # A tibble: 90 × 6
    ##         hitID gpsLat gpsLon gpsAlt  gpsTs_min  gpsTs_max
    ##         <int>  <dbl>  <dbl>  <dbl>      <dbl>      <dbl>
    ##  1   34126729   40.4  -76.1   106. 1505693095 1505776197
    ##  2   34126730   40.4  -76.1   106. 1505693095 1505776197
    ##  3   34126795   40.4  -76.1   106. 1505693095 1505776197
    ##  4   34126796   40.4  -76.1   106. 1505693095 1505776197
    ##  5   34126846   40.4  -76.1   106. 1505780097 1505863198
    ##  6   34126847   40.4  -76.1   106. 1505780097 1505863198
    ##  7   34128916   40.4  -76.1   105. 1505350490 1505433291
    ##  8   34128917   40.4  -76.1   105. 1505350490 1505433291
    ##  9 1136575629   44.0  -79.5   313. 1496797130 1496879031
    ## 10 1136575630   44.0  -79.5   313. 1496797130 1496879031
    ## # ℹ 80 more rows

3.  or the **`by = "closest"`** location in time
    - individual GPS lat/lons are returned, matching the closest `hitID`
      timestamp
    - this method is most accurate for mobile deployments, but is
      potentially slower than `by = X`.
    - you can also specify a `cutoff` which will only match GPS records
      which are within `cutoff = X` minutes of the hit. This way you can
      avoid having situations where the ‘closest’ GPS record is actually
      days away.

For example, the closest location in time noted within 2 hours of a hit.

``` r
index_GPS <- getGPS(src = gps_tags, data = rails, by = "closest", cutoff = 120)
index_GPS
```

    ## # A tibble: 90 × 6
    ##         hitID    gpsID gpsLat gpsLon gpsAlt      gpsTs
    ##         <int>    <int>  <dbl>  <dbl>  <dbl>      <dbl>
    ##  1   34126729 23978179   40.4  -76.1   111. 1505761796
    ##  2   34126730 23978179   40.4  -76.1   111. 1505761796
    ##  3   34126795 23978184   40.4  -76.1   100. 1505780097
    ##  4   34126796 23978184   40.4  -76.1   100. 1505780097
    ##  5   34126846 23978200   40.4  -76.1   106. 1505837998
    ##  6   34126847 23978200   40.4  -76.1   106. 1505837998
    ##  7   34128916 23978065   40.4  -76.1   100. 1505350490
    ##  8   34128917 23978065   40.4  -76.1   100. 1505350490
    ##  9 1136575629 22242037   44.0  -79.5   312. 1496846031
    ## 10 1136575630 22242037   44.0  -79.5   312. 1496846031
    ## # ℹ 80 more rows

To keep all `hitID`s, regardless of whether they match to GPS data or
not, use the argument `keepAll = TRUE`. This results in `NA` for
`gpsLat`, `gpsLon` and `gpsAlt` where there is no corresponding GPS hit
(otherwise the hit is omitted).

``` r
index_GPS <- getGPS(src = gps_tags, data = rails, keepAll = TRUE)
index_GPS
```

    ## # A tibble: 2,748 × 6
    ##       hitID gpsLat gpsLon gpsAlt gpsTs_min gpsTs_max
    ##       <int>  <dbl>  <dbl>  <dbl>     <dbl>     <dbl>
    ##  1 32811108     NA     NA     NA        NA        NA
    ##  2 32811109     NA     NA     NA        NA        NA
    ##  3 32912898     NA     NA     NA        NA        NA
    ##  4 32912899     NA     NA     NA        NA        NA
    ##  5 32913271     NA     NA     NA        NA        NA
    ##  6 32913272     NA     NA     NA        NA        NA
    ##  7 32913404     NA     NA     NA        NA        NA
    ##  8 32913405     NA     NA     NA        NA        NA
    ##  9 32913717     NA     NA     NA        NA        NA
    ## 10 32913718     NA     NA     NA        NA        NA
    ## # ℹ 2,738 more rows

## Using GPS locations

Now that we have our GPS data (either through loading `alltagsGPS` or
using the
[`getGPS()`](https://motuswts.github.io/motus/reference/getGPS.md)
function), we can use these coordinates when [cleaning our data in
Chapter
5](https://motuswts.github.io/motus/articles/05-data-cleaning.md).

In Chapter 5, we used the receiver deployment latitude and longitude:
`recvDepLat`, `recvDepLon`.

However, now that you have gps data, you can create receiver latitude
and longitude variables (`recvLat`, `recvLon`, `recvAlt`) based on the
coordinates recorded by the receiver GPS (`gpsLat`, `gpsLon`, `gpsAlt`),
and where those are not available, infilled with coordinates from the
receiver deployment metadata (`recvDeployLat`, `recvDeployLon`,
`recvDeployAlt`).

Missing GPS coordinates may appear as `NA` if they are missing, or as
`0` or `999` if there was a problem with the unit recording.

However, as we are changing values in the data, we’ll need to [flatten
the data
first](https://motuswts.github.io/motus/articles/03-accessing-data.html#converting-to-flat-data).

Using the example from Chapter 5 starting with [Checking
receivers](https://motuswts.github.io/motus/articles/05-data-cleaning.html#checking-receivers)

``` r
sql_motus <- tagme(176, dir = "./data/")
```

    ## Checking for new data in project 176

    ## Updating metadata

    ## activity:     1 new batch records to check

    ## batchID  1977125 (#     1 of      1): got    156 activity records

    ## Downloaded 156 activity records

    ## nodeData:     0 new batch records to check

    ## Fetching deprecated batches

    ## Total deprecated batches: 6
    ## New deprecated batches: 0

``` r
df_alltagsGPS <- tbl(sql_motus, "alltagsGPS") %>%
  mutate(recvLat = if_else(is.na(gpsLat) | gpsLat %in% c(0, 999), 
                           recvDeployLat, gpsLat),
         recvLon = if_else(is.na(gpsLon) | gpsLon %in% c(0, 999), 
                           recvDeployLon, gpsLon),
         recvAlt = if_else(is.na(gpsAlt), recvDeployAlt, gpsAlt)) %>%
  collect()  # Flatten the data

# Take a look
select(df_alltagsGPS, hitID, recvLat, recvLon)
```

    ## # A tibble: 108,999 × 3
    ##      hitID recvLat recvLon
    ##    <int64>   <dbl>   <dbl>
    ##  1   45107    42.6   -72.7
    ##  2   45108    42.6   -72.7
    ##  3   45109    42.6   -72.7
    ##  4   45110    42.6   -72.7
    ##  5   45111    42.6   -72.7
    ##  6  199885    42.7   -72.5
    ##  7  199886    42.7   -72.5
    ##  8  199887    42.7   -72.5
    ##  9  199888    42.7   -72.5
    ## 10  199889    42.7   -72.5
    ## # ℹ 108,989 more rows

[Continuing on in Chapter
5](https://motuswts.github.io/motus/articles/05-data-cleaning.html#checking-receivers)
with these values, you would then replace all instances of
`recvDeployLat` with `recvLat` and `recevDeployLon` with `recvLon`.

You would also use this flattened data frame, `df_alltagsGPS`, rather
than the un-flattened `tbl_alltagsGPS`.

> **What Next?** [Explore all
> articles](https://motuswts.github.io/motus/articles/index.md)
