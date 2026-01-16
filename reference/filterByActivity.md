# Filter `alltags` by `activity`

The `activity` table is used to identify batches with too much noise.
Depending on the value of `return` these are filtered out, returned, or
identified in the `alltags` view with the column `probability`. **No
changes to the database are made.**

## Usage

``` r
filterByActivity(
  src,
  return = "good",
  view = "alltags",
  minLen = 3,
  maxLen = 5,
  maxRuns = 100,
  ratio = 0.85
)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- return:

  Character. One of "good" (return only 'good' runs), "bad" (return only
  'bad' runs), "all" (return all runs, but with a new `probability`
  column which identifies 'bad' (0) and 'good' (1) runs.

- view:

  Character. Which view to use, one of "alltags" (faster) or
  "alltagsGPS" (with GPS data).

- minLen:

  Numeric. The minimum run length to allow (equal to or below this, all
  runs are 'bad')

- maxLen:

  Numeric. The maximum run length to allow (equal to or above this, all
  runs are 'good')

- maxRuns:

  Numeric. The cutoff of number of runs in a batch (see Details)

- ratio:

  Numeric. The ratio cutoff of runs length 2 to number of runs in a
  batch (see Details)

## Value

tbl_SQLiteConnection

## Details

Runs are identified by the following:

- All runs with a length \>= `maxLen` are **GOOD**

- All runs with a length \<= `minLen` are **BAD**

- Runs with a length between `minLen` and `maxLen` are **BAD** IF both
  of the following is true:

  - belong to a batch where the number of runs is \>= `maxRuns`

  - the ratio of runs with a length of 2 to the number of runs total is
    \>= `ratio`

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()

tbl_good <- filterByActivity(sql_motus)
tbl_bad <- filterByActivity(sql_motus, return = "bad")
tbl_all <- filterByActivity(sql_motus, return = "all")
```
