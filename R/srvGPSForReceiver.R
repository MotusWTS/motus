#' get the GPS fixes for a receiver from the data server
#'
#' These are the periodic GPS fixes from receivers belonging to the
#' project, and only makes sense for mobile receiver deployments.
#'
#' @param batchID integer scalar batch ID
#' @param ts real scalar processing timestamp of latest fix already owned
#' Default: 0, meaning none.
#'
#' @return data.frame with these columns:
#' \itemize{
#'    \item ts       numeric system timestamp
#'    \item gpsts    numeric GPS timestamp
#'    \item batchID  integer batch ID
#'    \item lat      numeric latitude in degrees N (negative is south)
#'    \item lon      numeric longitude in degrees E (negative is west)
#'    \item alt      numeric altitude in metres ASL
#' }
#'
#' @noRd

srvGPSForReceiver = function(batchID, gpsID = 0, verbose = FALSE) {
    x = srvQuery(API = motus_vars$API_GPS_FOR_RECEIVER, 
                 params = list(batchID = batchID, gpsID = gpsID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names = seq(along = x[[1]])))
}
