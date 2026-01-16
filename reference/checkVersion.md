# Check database version

Verifies the version of the package against the `admInfo` table of a
`.motus` file. Those should match if the `updateMotusDb()` function has
been properly applied by the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function.

## Usage

``` r
checkVersion(src)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.
