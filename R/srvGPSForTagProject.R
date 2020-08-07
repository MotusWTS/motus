#' get the GPS fixes for a tag project from the data server
#'
#' These are the periodic GPS fixes from receivers that detected
#' tags from the project.
#'
#' @param projectID Integer. Motus tag project ID
#' @param batchID Integer. Batch ID
#' @param gpsID Numeric. GPS ID of latest fix already owned. Default: 0, meaning
#'   none.
#'
#' @return data.frame with these columns:
#' \itemize{
#'    \item gpsID    numeric GPS ID
#'    \item ts       numeric system timestamp
#'    \item gpsts    numeric GPS timestamp
#'    \item batchID  integer batch ID
#'    \item lat      numeric latitude in degrees N (negative is south)
#'    \item lon      numeric longitude in degrees E (negative is west)
#'    \item alt      numeric altitude in metres ASL
#' }
#'
#' @note: this returns fixes from receivers which detected tags from the
#' given project.  Fixes from up to 1 hour before to 1 hour after the
#' detections are included, to ensure temporal coverage.
#' 
#' @noRd

srvGPSForTagProject = function(projectID, batchID, gpsID = 0, verbose = FALSE) {
    x <- srvQuery(API = motus_vars$API_GPS_FOR_TAG_PROJECT, 
                 params = list(projectID = projectID, batchID = batchID, 
                               gpsID = gpsID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names = seq(along = x[[1]])))
}
