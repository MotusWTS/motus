#' get the hits for a receiver project from the data server
#'
#' @param projectID integer scalar motus project ID
#' @param batchID integer scalar motus batch ID
#' @param hitID integer scalar ID of latest hit already obtained.
#' Default: 0, meaning none.
#' @param countOnly logical; if TRUE, return only the cound of available batches.
#' Default: FALSE.
#'
#' @return data.frame with these columns:
#' \itemize{
#'   \item hitID
#'   \item runID
#'   \item batchID
#'   \item ts
#'   \item sig
#'   \item sigSD
#'   \item noise
#'   \item freq
#'   \item freqSD
#'   \item slop
#'   \item burstSlop
#' }
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvHitsForReceiverProject = function(projectID, batchID, hitID=0, countOnly=FALSE) {
    x = srvQuery(API=Motus$API_HITS_FOR_RECEIVER_PROJECT, params=list(projectID=projectID, batchID=batchID, hitID=hitID, countOnly=countOnly))
    if (countOnly)
        return (x$count)
    else
        return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
