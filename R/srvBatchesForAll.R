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
#' @noRd
#'
#' @details this call is used to obtain batches incrementally, regardless of
#' which receiver they come from.  It is only available to administrative users,
#' and calling it as a non-administrative user stops with an error.

srvBatchesForAll = function(batchID=0, verbose = FALSE) {
    x = srvQuery(API=motus_vars$API_BATCHES_FOR_ALL, 
                 params=list(batchID=batchID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
