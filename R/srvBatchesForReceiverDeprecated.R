#' Fetch deprecated batches for a receiver
#'
#' @param deviceID Numeric. Motus receiver device ID
#' @param batchID Numeric. Largest batchID already fetched. For pagination,
#'   starts with 0 (default).
#' 
#' @noRd

srvBatchesForReceiverDeprecated <- function(deviceID, batchID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_BATCHES_FOR_RECEIVER_DEPRECATED, 
           params = list(deviceID = deviceID, batchID = batchID),
           verbose = verbose) %>%
    as.data.frame()
}
