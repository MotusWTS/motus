# Returns a dataframe of the filters stored in the local database.

Returns a dataframe of the filters stored in the local database.

## Usage

``` r
listRunsFilters(src)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

## Value

a dataframe
