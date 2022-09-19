#' Report how much new data motus has for a tag detection database
#'
#' "new" means data not already in your local database.
#' 
#' @inheritParams tagme
#'
#' @return a named list with these items:
#' 
#' - numBatches: number of batches having data for your database
#' - numRuns: number of runs of tags detections with new data
#' - numHits: number of new detections
#' - numGPS: number of new GPS fixes covering the new detections
#' - numBytes: estimated size of download, in bytes.  This is an estimate of the
#'   *uncompressed* size, but data are gz-compressed for transfer, so the number
#'   of bytes you have to download is typically going to be smaller than this
#'   number by a factor of 2 or more.
#'
#' @note if you specify `new = TRUE` and the database does not already exist, it
#'   will be created (but empty).
#'
#' @export


tellme <- function(projRecv, new = FALSE, dir = getwd()) {
  tagme(projRecv, new = new, dir = dir, update = TRUE, countOnly = TRUE)
}
