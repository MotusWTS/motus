# Common arguments

Common arguments

## Arguments

- projRecv:

  Numeric. Project code from motus.org, *or* character receiver serial
  number.

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- df_src:

  Data frame, SQLite connection, or SQLite table. An SQLite connection
  would be the result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`; an SQLite table
  would be the result of `dplyr::tbl(tags, "alltags")`; a data frame
  could be the result of
  `dplyr::tbl(tags, "alltags") %>% dplyr::collect()`.

- df:

  Data frame. Could be the result of
  `dplyr::tbl(tags, "alltags") %>% dplyr::collect()`.

- lat:

  Character. Name of column with latitude values, defaults to
  `recvDeployLat`.

- lon:

  Character. Name of column with longitude values, defaults to
  `recvDeployLon`.

- ts:

  Character. Name of column with timestamp values, defaults to `ts`.

- resume:

  Logical. Resume a download? Otherwise the table is removed and the
  download is started from the beginning.

- batchID:

  Numeric. Id of the batch in question

- batchMsg:

  Character. Message to share

- projectID:

  Numeric. Id of the Project in question

- filterName:

  Character. Unique name given to the filter

- motusProjID:

  Character. Optional project ID attached to the filter in order to
  share with other users of the same project.

- data:

  Defunct, use `src`, `df_src`, or `df` instead.
