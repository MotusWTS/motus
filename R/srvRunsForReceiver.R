#' Get the runs for a receiver
#'
#' @param batchID Integer. Batch ID
#' @param runID Integer. ID of latest run already obtained. Default: 0, meaning
#'   none.
#'
#' @noRd

srvRunsForReceiver <- function(batchID, runID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_RUNS_FOR_RECEIVER,
           params = list(batchID = batchID, runID = runID),
           verbose = verbose) %>%
    to_df()
}
