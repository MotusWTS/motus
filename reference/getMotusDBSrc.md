# Get the src_sqlite for a receiver or tag database

Receiver database files have names like "SG-1234BBBK06EA.motus" or
"Lotek-12345.motus", and project database files have names like
"project-52.motus".

## Usage

``` r
getMotusDBSrc(
  recv = NULL,
  proj = NULL,
  create = FALSE,
  dbDir = motus_vars$dbDir
)
```

## Arguments

- recv:

  receiver serial number

- proj:

  integer motus project number exactly one of `proj` or `recv` must be
  specified.

- create:

  Is this a new database? Default: FALSE. Same semantics as for
  [`src_sqlite()`](https://dplyr.tidyverse.org/reference/src_dbi.html)'s
  parameter of the same name: the DB must already exist unless you
  specify `create = TRUE`

- dbDir:

  path to folder with existing receiver databases Default:
  `motus_vars$dbDir`, which is set to the current folder by
  [`getwd()`](https://rdrr.io/r/base/getwd.html) when this library is
  loaded.

## Value

a src_sqlite for the receiver; if the receiver is new, this database
will be empty, but have the correct schema.
