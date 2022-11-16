#' Get information about the motus data server API
#'
#' The server is queried for a few details about the API.
#'
#' @noRd

srvAPIinfo <- function(verbose = FALSE) {
  srvQuery(API = motus_vars$API_API_INFO, params = list(), 
           auth = FALSE, verbose = verbose)
}
