#' Get the hits blu data batches for a tag project
#'
#' @param projectID Integer. Motus project ID
#' @param batchID Integer. Last Batch ID already available
#' @param lastBatchID Integer. Highest Batch ID that can be returned for this request
#'
#' @noRd

srvHitsBluBatchesForTagProject <- function(projectID, batchID, lastBatchID, verbose = FALSE) {
  srvQuery(API = motus_vars$API_HITS_BLU_BATCHES_FOR_TAG_PROJECT, 
           params = list(projectID = projectID, batchID = batchID, lastBatchID = lastBatchID),
           verbose = verbose) %>%
    to_df()
}
