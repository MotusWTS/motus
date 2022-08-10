#' Get the GPS fixes for a tag project
#'
#' These are the periodic GPS fixes from receivers that detected
#' tags from the project.
#'
#' @param projectID Integer. Motus tag project ID
#' @param batchID Integer. Batch ID
#' @param gpsID Numeric. GPS ID of latest fix already owned. Default: 0, meaning
#'   none.
#'
#' @note: this returns fixes from receivers which detected tags from the
#' given project.  Fixes from up to 1 hour before to 1 hour after the
#' detections are included, to ensure temporal coverage.
#' 
#' @noRd

srvGPSForTagProject <- function(projectID, batchID, gpsID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_GPS_FOR_TAG_PROJECT, 
           params = list(projectID = projectID, batchID = batchID, 
                         gpsID = gpsID),
           verbose = verbose) %>%
    as.data.frame()
}
