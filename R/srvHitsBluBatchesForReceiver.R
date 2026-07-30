#' Get the hits blu data batches for a receiver
#'
#' @param deviceID Integer. motus Device ID (receiver)
#' @param batchID Integer. Last Batch ID already available
#' @param lastBatchID Integer. Highest Batch ID that can be returned for this request
#'
#' @noRd

srvHitsBluBatchesForReceiver <- function(deviceID, batchID, lastBatchID, verbose = FALSE) {
  srvQuery(API = motus_vars$API_HITS_BLU_BATCHES_FOR_RECEIVER, 
           params = list(deviceID = deviceID, batchID = batchID, lastBatchID = lastBatchID),
           verbose = verbose) %>%
    to_df()
}
