# Map of tag routes and sites coloured by id

Google map of routes of Motus tag detections coloured by ID. User
defines a date range to show points for receivers that were operational
at some point during the date range.

## Usage

``` r
plotRouteMap(
  src,
  maptype = "osm",
  zoom = NULL,
  start_date = NULL,
  end_date = NULL,
  lim_lat = NULL,
  lim_lon = NULL,
  data,
  lat,
  lon,
  recvStart,
  recvEnd
)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- maptype:

  Character. Map tiles to use. Must be one of
  [`rosm::osm.types()`](https://rdrr.io/pkg/rosm/man/deprecated.html),
  such as `osm`, `stamenbw`, etc. Most map tiles require attribution for
  publication, see details.

- zoom:

  Integer. Override the calculated zoom level to increase or decrease
  the resolution of the map tiles.

- start_date:

  Character. Optional start date for routes.

- end_date:

  Character. Optional end date for routes.

- lim_lat:

  Numeric vector. Optional latitudinal plot limits.

- lim_lon:

  Numeric vector. Optional longitudinal plot limits.

- data:

  Defunct, use `src`, `df_src`, or `df` instead.

- lat:

  Defunct

- lon:

  Defunct

- recvStart:

  Defunct

- recvEnd:

  Defunct

## Details

By default this function uses OSM maps (Open Street Map). OSM and many
other map tiles are released under specific licences, which generally
require that you give attribution at a minimum. See
[OSM](https://www.openstreetmap.org/copyright) for more details on their
tiles, but remember to check what other groups require if you use their
tiles.

## Examples

``` r
if (FALSE) { # interactive()
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

# Plot route map of all detection data, with "osm" maptype, and receivers
# active between 2016-01-01 and 2017-01-01
plotRouteMap(sql_motus, start_date = "2016-01-01", end_date = "2016-12-31")
}
```
