#' get the runs for a receiver project from the data server
#'
#' @param projectID integer scalar motus project ID
#' @param batchID integer scalar motus batch ID
#' @param runID integer scalar ID of latest run already obtained.
#' Default: 0, meaning none.
#'
#' @return a list with these items:
#' \itemize{
#'    \item runs, a data.frame with these columns:
#'       \itemize{
#'          \item runID
#'          \item batchIDbegin
#'          \item tsBegin
#'          \item tsEnd
#'          \item done
#'          \item motusTagID
#'          \item ant
#'          \item len
#'       }
#'    \item batchRuns, a data.frame with these columns:
#'       \itemize{
#'          \item batchID
#'          \item runID
#'       }
#' }
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvRunsForReceiverProject = function(projectID, batchID, runID=0) {
    x = srvQuery(API=Motus$API_RUNS_FOR_RECEIVER_PROJECT, params=list(projectID=projectID, batchID=batchID, runID=runID))
    return (list(
        runs = structure(x$runs, class = "data.frame", row.names=seq(along=x$runs[[1]])),
        batchRuns = structure(x$batchRuns, class = "data.frame", row.names=seq(along=x$batchRuns[[1]]))
        ))
}
