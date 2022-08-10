#' Get the batches for a receiver
#'
#' @param deviceID Integer. Motus device ID
#' @param batchID Integer. Largest batchID already owned for this project.
#'   Default: 0, meaning none.
#'
#' @noRd

srvBatchesForReceiver <- function(deviceID, batchID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_BATCHES_FOR_RECEIVER, 
           params = list(deviceID = deviceID, batchID = batchID),
           verbose = verbose) %>%
    to_df()
}
