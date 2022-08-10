#' Get the GPS fixes for a receiver
#'
#' These are the periodic GPS fixes from receivers belonging to the
#' project, and only makes sense for mobile receiver deployments.
#'
#' @param batchID Integer. Batch ID
#' @param ts Numeric. Processing timestamp of latest fix already owned Default:
#'   0, meaning none.
#'   
#'
#' @noRd

srvGPSForReceiver <- function(batchID, gpsID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_GPS_FOR_RECEIVER, 
           params = list(batchID = batchID, gpsID = gpsID),
           verbose = verbose) %>%
    as.data.frame()
}
