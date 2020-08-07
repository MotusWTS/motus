#' get the runs for a tag project in a batch from the data server
#'
#' @param projectID integer scalar motus project ID
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

srvRunsForTagProject = function(projectID, batchID, runID = 0, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_RUNS_FOR_TAG_PROJECT, 
                params = list(projectID = projectID, 
                              batchID = batchID, 
                              runID = runID),
                verbose = verbose)
  return (structure(x, class = "data.frame", row.names = seq(along = x[[1]])))
}
