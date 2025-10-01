#' Get the hits blu data for a receiver
#'
#' @param batchID Integer. Batch ID
#' @param hitID Integer. Hit ID of latest hit already obtained. Default: 0,
#'   meaning none.
#'
#' @noRd

srvHitsBluForReceiver <- function(batchID, hitID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_HITS_BLU_FOR_RECEIVER, 
           params = list(batchID = batchID, hitID = hitID),
           verbose = verbose) %>%
    to_df()
}
