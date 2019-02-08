#' get new batches for all receivers from the data server
#'
#' @param batchID integer largest batchID already obtained.
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
#' @export
#'
#' @details this call is used to obtain batches incrementally, regardless of
#' which receiver they come from.  It is only available to administrative users,
#' and caling it as a non-administrative user stops with an error.
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvBatchesForAll = function(batchID=0) {
    x = srvQuery(API=Motus$API_BATCHES_FOR_ALL, params=list(batchID=batchID))
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
