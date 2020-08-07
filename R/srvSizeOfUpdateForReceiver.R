#' get the amount of data required to update a receiver project from the data server
#'
#' @param deviceID integer scalar motus device ID
#' @param batchID integer largest batchID already owned for this project.
#' Default: 0, meaning none.
#'
#' @return a list with these items:
#' \itemize{
#' \item numBatches - number of new batches
#' \item numRuns - number of new or updated runs
#' \item numHits - number of new hits
#' \item numGPS - number of GPS fixes
#' \item size - estimate of transfer size, in bytes
#' }
#'
#' @noRd

srvSizeOfUpdateForReceiver = function(deviceID, batchID=0, verbose = FALSE) {
    x = srvQuery(API=motus_vars$API_SIZE_OF_UPDATE_FOR_RECEIVER, 
                 params=list(deviceID=deviceID, batchID=batchID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
