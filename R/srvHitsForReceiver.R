#' Get the hits for a receiver
#'
#' @param batchID Integer. Batch ID
#' @param hitID Integer. Hit ID of latest hit already obtained. Default: 0,
#'   meaning none.
#'
#' @noRd

srvHitsForReceiver <- function(batchID, hitID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_HITS_FOR_RECEIVER, 
           params = list(batchID = batchID, hitID = hitID),
           verbose = verbose) %>%
    as.data.frame()
}
