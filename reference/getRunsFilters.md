# Get runsFilters

Returns a dataframe of the `runsFilters` records matching a filter name
(and optionally a project ID) stored in the local database.

## Usage

``` r
getRunsFilters(src, filterName, motusProjID = NA)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- filterName:

  Character. Unique name given to the filter

- motusProjID:

  Character. Optional project ID attached to the filter in order to
  share with other users of the same project.

## Value

a database connection to `src`
