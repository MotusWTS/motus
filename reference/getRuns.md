# Returns a dataframe containing runs

Specifically the `runID` and `motusTagID`, `ambigID` and `tsBegin` to
`tsEnd` (timestamp) range of runs, filtered by optional parameters. The
`match.partial` parameter (default = TRUE) determines how timestamp
filtering works. When `match.partial` is FALSE, `runID`'s are only
included when both `tsBegin` and `tsEnd` falls between `ts.min` and
`ts.max` (only includes runs when they entirely contained in the
specified range). When match.partial is TRUE, `runID`'s are returned
whenever the run partially matches the specified period.

## Usage

``` r
getRuns(
  src,
  ts.min = NA,
  ts.max = NA,
  match.partial = TRUE,
  motusTagID = c(),
  ambigID = c()
)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- ts.min:

  minimum timestamp used to filter the dataframe, Default: NA

- ts.max:

  maximum timestamp used to filter the dataframe, Default: NA

- match.partial:

  whether runs that partially overlap the specified ts range are
  included, Default: TRUE

- motusTagID:

  vector of Motus tag ID's used to filter the resulting dataframe,
  Default: c()

- ambigID:

  vector of ambig ID's used to filter the resulting dataframe, Default:
  c()

## Value

a dataframe containing the runID, the motusTagID and the ambigID (if
applicable) of runs
