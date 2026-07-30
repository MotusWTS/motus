# Update hitsBlu data

Add any missing BLUtag hits to the `hitsBlu` table in an existing Motus
database. `hitsBlu` contain extra information regarding the 'health' of
portable node units. Use
[`getBluPayload()`](https://motuswts.github.io/motus/reference/getBluPayload.md)
to extract these details from the payload data.

## Usage

``` r
hitsBlu(src)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

## Details

This function is only required if you suspect BLUtag hits have been
missed (due to hits being downloaded before the motus package had the
functionality to download BLUtag hits).

## See also

[`getBluPayload()`](https://motuswts.github.io/motus/reference/getBluPayload.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  hitsBlu(my_tags)
} # }
```
