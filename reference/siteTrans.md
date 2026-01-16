# Summarize transitions between sites for each tag

Creates a dataframe of transitions between sites; detections are ordered
by detection time, then "transitions" are identified as the period
between the final detection at site x (possible "departure"), and the
first detection (possible "arrival") at site y (ordered
chronologically). Each row contains the last detection time and lat/lon
of site x, first detection time and lat/lon of site y, distance between
the site pair, time between detections, rate of movement between
detections, and bearing between site pairs.

## Usage

``` r
siteTrans(data, latCoord = "recvDeployLat", lonCoord = "recvDeployLon")
```

## Arguments

- data:

  a selected table from .motus data, eg. "alltagsGPS", or a data.frame
  of detection data including at a minimum variables for `ts`,
  `motusTagID`, `tagDeployID`, `recvDeployName`, and a
  latitude/longitude

- latCoord:

  a variable with numeric latitude values, defaults to `recvDeployLat`

- lonCoord:

  a variable with numeric longitude values, defaults to `recvDeployLon`

## Value

a data.frame with these columns:

- fullID: fullID of Motus registered tag

- ts.x: time of last detection of tag at site.x ("departure" time)

- lat.x: latitude of site.x

- lon.x: longitude of site.x

- site.x: first site in transition pair (the "departure" site)

- ts.y: time of first detection of tag at site.y ("arrival" time)

- lat.y: latitude of site.y

- lon.y: longitude of site.y

- site.y: second site in transition pair (the "departure" site)

- tot_ts: length of time between ts.x and ts.y (in seconds)

- dist: total straight line distance between site.x and site.y (in
  metres), see `sensorgnome::latLonDist()` for details

- rate: overall rate of movement (tot_ts/dist), in metres/second

- bearing: bearing between first and last detection sites, see bearing
  function in geosphere package for more details

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# convert sql file "sql_motus" to a tbl called "tbl_alltags"
library(dplyr)
tbl_alltags <- tbl(sql_motus, "alltagsGPS") 
 
## convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
 df_alltags <- tbl_alltags %>%
   collect() %>%
   as.data.frame()

# View all site transitions for all detection data from tbl file tbl_alltags
transitions <- siteTrans(tbl_alltags)

# View site transitions for only tag 16037 from data.frame df_alltags using
# gpsLat/gpsLon
transitions <- siteTrans(filter(df_alltags, motusTagID == 16037),
                           latCoord = "gpsLat", lonCoord = "gpsLon")
```
