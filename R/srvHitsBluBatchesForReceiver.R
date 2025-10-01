#' Get the hits blu data batches for a receiver
#'
#' @param batchID Integer. Last Batch ID already available
#'
#' @noRd

srvHitsBluBatchesForReceiver <- function(batchID, verbose = FALSE) {
  srvQuery(API = motus_vars$API_HITS_BLU_BATCHES_FOR_RECEIVER, 
           params = list(batchID = batchID),
           verbose = verbose) %>%
    to_df()
}
