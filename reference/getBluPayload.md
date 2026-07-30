# Extract variables from BLUtag Payloads

Extracts the data from the hexadecimal BLUtag payload into new columns.

## Usage

``` r
getBluPayload(df_src)
```

## Arguments

- df_src:

  Data frame, SQLite connection, or SQLite table. An SQLite connection
  would be the result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`; an SQLite table
  would be the result of `dplyr::tbl(tags, "alltags")`; a data frame
  could be the result of
  `dplyr::tbl(tags, "alltags") %>% dplyr::collect()`.

## Value

Data frame/Tibble of the BLUtag hits with extra variable columns.

## Examples

``` r
# With example, dummy data
t <- data.frame(hitID = 99999999, batchID = 9999999, sync = 49000, product = 1, revision = 0)
t <- cbind(t, payload = c("6406060F", "6706150F", "6106270F", NA))
t 
#>   hitID batchID  sync product revision  payload
#> 1 1e+08 9999999 49000       1        0 6406060F
#> 2 1e+08 9999999 49000       1        0 6706150F
#> 3 1e+08 9999999 49000       1        0 6106270F
#> 4 1e+08 9999999 49000       1        0     <NA>

# Extract payload
getBluPayload(t)
#>   hitID batchID  sync product revision  payload solar_voltage temperature
#> 1 1e+08 9999999 49000       1        0 6406060F         1.636       38.46
#> 2 1e+08 9999999 49000       1        0 6706150F         1.639       38.61
#> 3 1e+08 9999999 49000       1        0 6106270F         1.633       38.79
#> 4 1e+08 9999999 49000       1        0     <NA>            NA          NA

if (FALSE) { # \dontrun{
  t <- tagme(XXX, update = TRUE, new = TRUE) # Hits with BLUTags
  getBluPayload(t) # Extract payload from the database
  getBluPayload(dplyr::tbl(t, "hitsBlu")) # Or supply the hitsBlu table directly
} # }
```
