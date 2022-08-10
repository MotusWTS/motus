#' Get the batches for a tag project
#'
#' @param projectID Integer. Motus project ID
#' @param batchID Integer. Largest batchID already owned for this project.
#'   Default: 0, meaning none.
#'
#' @noRd

srvBatchesForTagProject <- function(projectID, batchID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_BATCHES_FOR_TAG_PROJECT, 
           params = list(projectID = projectID, batchID = batchID),
           verbose = verbose) %>%
    as.data.frame()
}
