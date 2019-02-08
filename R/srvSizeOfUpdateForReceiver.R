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
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvSizeOfUpdateForReceiver = function(deviceID, batchID=0) {
    x = srvQuery(API=Motus$API_SIZE_OF_UPDATE_FOR_RECEIVER, params=list(deviceID=deviceID, batchID=batchID))
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
