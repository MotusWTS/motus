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
#'
#' @author John Brzustowski
#'     \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusLogout = function () {
    motus_vars$authToken = NULL
    motus_vars$userLogin = NULL
    motus_vars$userPassword = NULL
    message("   Salut - bye bye!")
}
