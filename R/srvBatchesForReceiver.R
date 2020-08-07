#' get the batches for a receiver from the data server
#'
#' @param deviceID integer scalar motus device ID
#' @param batchID integer largest batchID already owned for this project.
#' Default: 0, meaning none.
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

srvBatchesForReceiver = function(deviceID, batchID=0, verbose = FALSE) {
    x = srvQuery(API=motus_vars$API_BATCHES_FOR_RECEIVER, 
                 params=list(deviceID=deviceID, batchID=batchID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
