# args ------------------
#' Common arguments 
#'
#' @param projRecv Numeric project code from motus.org, *or* character receiver
#'   serial number.
#' @param src SQLite connection (result of `tagme(XXX)` or
#'   `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`)
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
#' @keywords internal
#' @name args
NULL