
#' Sets global options for timeouts
#' 
#' Sets, resets or returns the "motus.timeout" global option used by all API
#' access functions (including `tagme()`). If `timeout` is a number and `reset` 
#' is `FALSE`, the API timeout is set to `timeout` number of seconds. If `reset`
#' is `TRUE`, the API timeout is reset to the default of 120 seconds. If no
#' `timeout` is defined and `reset = FALSE`, the current value of the timeout 
#' is returned.
#' 
#' By default the timeout is 120s, which generally should
#' give the server sufficient time to prepare the data without having the user
#' wait for too long if the API is unavailable. However, some projects take 
#' unusually long to compile the data, so a longer timeout may be warranted in
#' those situations. This is equivalent to `options(motus.timeout = timeout)`
#'
#' @param timeout Numeric. Number of seconds to wait for a response from the 
#'   server. Increase if you're working with a project that requires extra time
#'   to process and serve the data.
#' @param reset Logical. Whether to reset the timeout to the default (120s;
#'   default `FALSE`). If `TRUE`, `timeout` is ignored.
#'
#' @return
#' @export
#' 
#' @seealso [resetTimeout()]
#'
#' @examples
#' srvTimeout()   # get the timeout value
#' srvTimeout(5)  # set the timeout value
#' srvTimeout()   # get the timeout value
#' 
#' \dontrun{
#' # No problem with default timeouts
#' t <- tagme(176, new = TRUE)
#' 
#' # But setting the timeout too short results in a server timeout
#' srvTimeout(0.001)
#' t <- tagme(176, new = TRUE)
#' }
#' 
srvTimeout <- function(timeout, reset = FALSE) {
  if(reset) {
    options(motus.timeout = 120)
  } else if(!missing(timeout)) {
    options(motus.timeout = timeout)
  } else return(options("motus.timeout"))
}

