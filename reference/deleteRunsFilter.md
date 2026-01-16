# Delete a filter

Deletes a filter by name or project ID.

## Usage

``` r
deleteRunsFilter(src, filterName, motusProjID = NA, clearOnly = FALSE)
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

- clearOnly:

  Logical. When true, only remove the probability records associated
  with the filter, but retain the filter itself

## Value

the integer `filterID` of the filter deleted
