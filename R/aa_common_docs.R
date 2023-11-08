# args ------------------
#' Common arguments 
#'
#' @param projRecv Numeric. Project code from motus.org, *or* character receiver
#'   serial number.
#' @param src SQLite connection. Result of `tagme(XXX)` or
#'   `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.
#' @param df_src Data frame, SQLite connection, or SQLite table. An SQLite
#'   connection would be the result of `tagme(XXX)` or
#'   `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`; an SQlite table would be
#'   the result of `dplyr::tbl(tags, "alltags")`; a data frame could be the
#'   result of `dplyr::tbl(tags, "alltags") %>% dplyr::collect()`.
#' @param df Data frame. Could be the result of `dplyr::tbl(tags, "alltags") %>%
#'   dplyr::collect()`.
#'   
#' @param lat Character. Name of column with latitude values, defaults to
#'   `recvDeployLat`.
#' @param lon Character. Name of column with longitude values, defaults to
#'   `recvDeployLon`.
#' @param ts Character. Name of column with timestamp values, defaults to `ts`.
#'   
#' @param resume Logical. Resume a download? Otherwise the table is
#'   removed and the download is started from the beginning.
#'   
#' @param batchID Numeric. Id of the batch in question
#' @param batchMsg Character. Message to share
#' @param projectID Numeric. Id of the Project in question
#' 
#' @param filterName Character. Unique name given to the filter
#' @param motusProjID Character. Optional project ID attached to the filter in
#'   order to share with other users of the same project.
#'   
#' @param data Defunct, use `df_src` instead.
#'   
#' @keywords internal
#' @name args
NULL