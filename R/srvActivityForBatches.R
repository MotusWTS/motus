#' get the activity of specific batches from the data server
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

srvActivityForBatches <- function(batchID = 0, ant = NULL, hourBin = NULL, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_ACTIVITY_FOR_BATCHES,
                params = list(batchID = batchID, ant = ant, hourBin = hourBin),
                verbose = verbose)
  return (structure(x, class = "data.frame", row.names = seq(along = x[[1]])))
}
