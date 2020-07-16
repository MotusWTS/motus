#' report how much new data motus has for a tag detection database
#'
#' "new" means data not already in your local database.
#'
#' @param projRecv integer scalar project code from motus.org, *or*
#' character scalar receiver serial number
#'
#' @param new logical scalar: is this a new database?  Default: FALSE
#' You have to specify \code{new=TRUE} if you want a new local copy of the
#' database to be created.  Otherwise, \code{tellme()} assumes the database
#' already exists, and will stop with an error if it cannot find it
#' in the current directory.  This is mainly to prevent inadvertent
#' downloads of large amounts of data that you already have!
#'
#' @param dir path to the folder where you are storing databases
#' Default: the current directory; i.e. \code{getwd()}
#'
#' @return a named list with these items:
#' \itemize{
#'    \item numBatches: number of batches having data for your database
#'    \item numRuns: number of runs of tags detections with new data
#'    \item numHits: number of new detections
#'    \item numGPS: number of new GPS fixes covering the new detections
#'    \item numBytes: estimated size of download, in bytes.  This is
#'          an estimate of the \emph{uncompressed} size, but
#'          data are gz-compressed for transfer, so the number of bytes
#'          you have to download is typically going to be smaller than
#'          this number by a factor of 2 or more.
#' }
#'
#' @note if you specify \code{new=TRUE} and the database does not already exist,
#' it will be created (but empty).
#'
#' @seealso \code{\link{tellme}}, which is a synonym for \code{tagme(..., countOnly=TRUE)}
#'
#' @export


tellme = function(projRecv, new=FALSE, dir=getwd()) {
    tagme(projRecv, new=new, dir=dir, update=TRUE, countOnly=TRUE)
}
