#' get the batches for a tag project from the data server
#'
#' @param projectID integer scalar motus project ID
#' @param batchID integer largest batchID already owned for this project.
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

srvBatchesForTagProject = function(projectID, batchID=0, verbose = FALSE) {
    x = srvQuery(API = motus_vars$API_BATCHES_FOR_TAG_PROJECT, 
                 params = list(projectID = projectID, batchID = batchID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
