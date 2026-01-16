# Create a new filter records that can be applied to runs

Create a new filter records that can be applied to runs

## Usage

``` r
createRunsFilter(src, filterName, motusProjID = NA, descr = NA, update = FALSE)
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

- descr:

  Character. Optional filter description detailing what the filter is
  meant to do

- update:

  Logical. Whether the filter record gets updated when a filter with the
  same name already exists.

## Value

an integer `filterID`
