#' Authenticate with the data server.
#'
#' Use motus_vars$userLogin and motus_vars$userPassword to get an authentication
#' token from the data server.
#'
#' @return a character scalar authentication/authorization token
#'
#' @details if login is unsuccessful, execution stops with an error message
#'
#' @seealso \code{\link{motus_vars}}
#'
#' @noRd

srvAuth = function(verbose = FALSE) {
  ## force lookup of userLogin and userPassword using their active bindings.
  ## (we don't want to use lazy evaluation here by instead passing the list(...)
  ## expression to srvQuery
  pars <- list(user = motus_vars$userLogin, 
               password = motus_vars$userPassword,
               pkgVersion = pkg_version())
  tryCatch({
    res <- srvQuery(motus_vars$API_DATA_AUTHENTICATE, pars, auth=FALSE, verbose = verbose)
    motus_vars$projects <- res$projects
    motus_vars$receivers <- res$receivers
    motus_vars$dataVersion <- res$dataVersion
    motus_vars$currentPkgVersion <- res$currentPkgVersion
    
    if("versionWarn" %in% names(res)) warning(res$versionWarn, call. = FALSE)
    
    return(res$authToken)
  }, error = function(e) {
    motus_vars$userLogin = NULL
    motus_vars$userPassword = NULL
    stop("Login failed with error message\n'", e$message, "'",
         call. = FALSE)
  })
}

# This way we can use mocking in tests
pkg_version <- function() utils::packageDescription("motus", fields = "Version")