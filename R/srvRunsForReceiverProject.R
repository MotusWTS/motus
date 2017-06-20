#' get the runs for a receiver project from the data server
#'
#' @param projectID integer scalar motus project ID
#' @param batchID integer scalar motus batch ID
#' @param runID integer scalar ID of latest run already obtained.
#' Default: 0, meaning none.
#' @param countOnly logical; if TRUE, return only the cound of available batches.
#' Default: FALSE.
#'
#' @return data.frame with these columns:
#' \itemize{
#' \item runID
#' \item batchIDbegin
#' \item batchIDend
#' \item motusTagID
#' \item ant
#' \item len
#' }
#'
#' @note see https://github.com/jbrzusto/motus/issues/1 for a detailed
#' description of what "in a batch" means for a run.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvRunsForReceiverProject = function(projectID, batchID, runID=0, countOnly=FALSE) {
    x = srvQuery(API=Motus$API_RUNS_FOR_RECEIVER_PROJECT, params=list(projectID=projectID, batchID=batchID, runID=runID, countOnly=countOnly))
    if (countOnly)
        return (x$count)
    else
        return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
