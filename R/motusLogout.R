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
#'    \item Motus$authToken
#'    \item Motus$userLogin
#'    \item Motus$userPassword
#' }
#' Due to their active bindings, subsequent calls to
#' any functions that need them will prompt for a login.
#'
#' @export
#'
#' @author John Brzustowski
#'     \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusLogout = function () {
    Motus$authToken = NULL
    Motus$userLogin = NULL
    Motus$userPassword = NULL
    cat("\n   Salut - bye bye!\n\n")
}
