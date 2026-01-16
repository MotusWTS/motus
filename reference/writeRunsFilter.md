# Write to the local database the probabilities associated with runs for a filter

Write to the local database the probabilities associated with runs for a
filter

## Usage

``` r
writeRunsFilter(
  src,
  filterName,
  motusProjID = NA,
  df,
  overwrite = TRUE,
  delete = FALSE
)
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

- df:

  Data frame. Containing `runID`, `motusTagID` and probability values to
  save in the local database

- overwrite:

  Logical. When `TRUE` ensures that existing records matching the same
  `filterName` and `runID` get replaced

- delete:

  Logical. When TRUE, removes all existing filter records associated
  with the `filterName` and re-inserts the ones contained in the
  dataframe. This option should be used if the dataframe provided
  contains the entire set of filters you want to save.

## Value

database connection refering to the filter created
