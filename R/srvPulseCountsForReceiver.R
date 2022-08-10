#' Get the pulse counts for an antenna
#'
#' Pulse counts summarize antenna activity on an hourly basis.
#'
#' @param batchID Integer. Batch ID
#' @param ant Integer. Antenna number
#' @param hourBin Integer. Hour bin, i.e. `floor(timestamp/3600)` for the pulses
#'   in this bin.  Default: 0, meaning no pulse counts have been obtained for
#'   this batch.  When 0, `ant` is ignored
#'
#' @noRd
#'
#' @note Paging for this query is handled by passing the last `ant` and
#'   `hourBin` values received to the next call of this function.  Values are
#'   returned sorted by `hourBin` *within* `ant` for each `batchID.`

srvPulseCountsForReceiver <- function(batchID, ant, hourBin = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_PULSE_COUNTS_FOR_RECEIVER, 
           params = list(batchID = batchID, ant = ant, hourBin = hourBin),
           verbose = verbose) %>%
    as.data.frame()
}
