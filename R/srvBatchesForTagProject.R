#' get the batches for a tag project from the data server
#'
#' @param projectID integer scalar motus project ID
#' @param ts real scalar processing timestamp of latest batch already owned
#' Default: 0, meaning none.
#' @param countOnly logical; if TRUE, return only the cound of available batches.
#' Default: FALSE.
#'
#' @return data.frame with these columns:
#' \itemize{
#' \item batchID integer motus batch ID
#' \item deviceID integer motus device ID
#' \item monoBN boot number, for SG receivers; NA for Lotek
#' \item tsBegin first timestamp of data
#' \item tsEnd last timestamp of data
#' \item numHits integer number of hits
#' \item ts real processing timestamp
#' }
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvBatchesForTagProject = function(projectID, ts=0, countOnly=FALSE) {
    x = srvQuery(API=Motus$API_BATCHES_FOR_TAG_PROJECT, params=list(projectID=projectID, ts=ts, countOnly=countOnly))
    if (countOnly)
        return (x$count)
    else
        return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
