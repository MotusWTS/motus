#' get information about the motus data server API
#'
#' The server is queried for a few details about the API.
#'
#' @return
#' a list with (at least) these items:
#' \itemize{
#'    \item maxRows; integer; maximum number of rows returned by any API calls
#' }
#'
#' @noRd

srvAPIinfo = function(verbose = FALSE) {
    return(srvQuery(API=motus_vars$API_API_INFO, params=list(), 
                    auth=FALSE, verbose = verbose))
}
