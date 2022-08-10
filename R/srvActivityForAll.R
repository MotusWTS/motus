#' Get the activity of specific batches for all
#'
#' @param batchID Integer. Next batchID to query
#' @param ant Integer. Next antenna to query
#' @param hourBin Integer. Next hourBin to query
#'
#' @noRd

srvActivityForAll <- function(batchID = 0, ant = NULL, hourBin = NULL, verbose = FALSE) {
  srvQuery(API = motus_vars$API_ACTIVITY_FOR_ALL,
           params = list(batchID = batchID, ant = ant, hourBin = hourBin),
           verbose = verbose) %>%
    as.data.frame()
}
