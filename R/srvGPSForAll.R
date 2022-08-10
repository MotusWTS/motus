#' Get the GPS points of specific batches for all
#'
#' @param batchID Integer. Next batchID to query
#' @param ant Integer. Next antenna to query
#' @param hourBin Integer. Next hourBin to query
#' 
#' @noRd

srvGPSForAll <- function(gpsID = 0, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_GPS_FOR_RECIEVER_ALL,
                params = list(gpsID = gpsID),
                verbose = verbose)
  
  as.data.frame(x)
}
