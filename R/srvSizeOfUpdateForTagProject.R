#' get the amount of data required to update a tag project from the data server
#'
#' @param projectID integer scalar motus project ID
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

srvSizeOfUpdateForTagProject = function(projectID, batchID=0) {
    x = srvQuery(API=Motus$API_SIZE_OF_UPDATE_FOR_TAG_PROJECT, params=list(projectID=projectID, batchID=batchID))
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
