# Convert points to path

Converts a data frame with a list of lat/lons to a spatial data frame
with MULTILINES defining paths by tag id. Useful for plotting with
[`ggplot2::geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html).
Will silently remove single points.

## Usage

``` r
points2Path(df, by = "fullID", lat = "recvDeployLat", lon = "recvDeployLon")
```

## Arguments

- df:

  Data frame. Could be the result of
  `dplyr::tbl(tags, "alltags") %>% dplyr::collect()`.

- by:

  Character. Column defining the tag id over which to group points into
  paths. Defaults to "fullID".

- lat:

  Character. Name of column with latitude values, defaults to
  `recvDeployLat`.

- lon:

  Character. Name of column with longitude values, defaults to
  `recvDeployLon`.

## Value

Spatial data frame with MULTILINE paths
