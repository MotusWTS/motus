#' get the runs for a receiver from the data server
#'
#' @param batchID integer scalar motus batch ID
#' @param runID integer scalar ID of latest run already obtained.
#' Default: 0, meaning none.
#'
#' @return a data.frame with these columns:
#' \itemize{
#'    \item runID
#'    \item batchIDbegin
#'    \item tsBegin
#'    \item tsEnd
#'    \item done
#'    \item motusTagID
#'    \item ant
#'    \item len
#' }
#'
#' @noRd

srvRunsForReceiver = function(batchID, runID=0, verbose = FALSE) {
    x = srvQuery(API=motus_vars$API_RUNS_FOR_RECEIVER,
                 params=list(batchID=batchID, runID=runID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
