#' get the runs for a tag project in a batch from the data server
#'
#' @param projectID integer scalar motus project ID
#' @param batchID integer scalar motus batch ID
#' @param runID integer scalar ID of latest run already obtained.
#' Default: 0, meaning none.
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

srvRunsForTagProject = function(projectID, batchID, runID=0) {
    x = srvQuery(API=Motus$API_RUNS_FOR_TAG_PROJECT, params=list(projectID=projectID, batchID=batchID, runID=runID))
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
