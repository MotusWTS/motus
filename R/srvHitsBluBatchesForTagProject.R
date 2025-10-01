#' Get the hits blu data batches for a tag project
#'
#' @param projectID Integer. Motus project ID
#' @param batchID Integer. Last Batch ID already available
#'
#' @noRd

srvHitsBluBatchesForTagProject <- function(projectID, batchID, verbose = FALSE) {
  srvQuery(API = motus_vars$API_HITS_BLU_BATCHES_FOR_TAG_PROJECT, 
           params = list(projectID = projectID, batchID = batchID),
           verbose = verbose) %>%
    to_df()
}
