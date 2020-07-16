#' Forget login credentials for motus.
#'
#' Any requests to the motus data server after calling
#' this function will require re-entering a username and
#' password.
#'
#' @return TRUE.
#'
#' @details This function just resets these items to NULL:
#' \itemize{
#'    \item motus_vars$authToken
#'    \item motus_vars$userLogin
#'    \item motus_vars$userPassword
#' }
#' Due to their active bindings, subsequent calls to
#' any functions that need them will prompt for a login.
#'
#' @export

motusLogout = function () {
  sessionVariable(name = "authToken", srvAuth)
  sessionVariable("userLogin", "login name at motus.org")
  sessionVariable("userPassword", "password at motus.org")
  message("   Salut - bye bye!")
}
