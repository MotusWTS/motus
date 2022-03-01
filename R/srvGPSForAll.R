#' get the GPS points of specific batches for all
#'
#' @param batchID Integer. Next batchID to query
#' @param ant Integer. Next antenna to query
#' @param hourBin Integer. Next hourBin to query
#'
#' @return data.frame with these columns:
#' \itemize{
#' \item batchID integer motus batch ID
#' \item motusDeviceID integer motus device ID
#' \item monoBN boot number, for SG receivers; NA for Lotek
#' \item tsStart first timestamp of data
#' \item tsEnd last timestamp of data
#' \item numHits integer number of hits
#' \item ts real processing timestamp
#' }
#' 
#' @noRd

srvGPSForAll <- function(gpsID = 0, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_GPS_FOR_RECIEVER_ALL,
                params = list(gpsID = gpsID),
                verbose = verbose)
  
  as.data.frame(x)
}
