#' Authenticate with the data server.
#'
#' This function uses Motus$userLogin and Motus$userPassword to get
#' an authentication token from the data server.
#'
#' @return a character scalar authentication/authorization token
#'
#' @details if login is unsuccessful, execution stops with error message
#'
#' @seealso \link{\code{Motus}}
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvAuth = function() {
    res = srvQuery(Motus$API_DATA_AUTHENTICATE, list(user=Motus$userLogin, password=Motus$userPassword), auth=FALSE)
    if (is.null(res$error)) {
        Motus$projects = res$projects
        return(res$authToken)
    } else {
        stop("Login with data server failed.  You can try again after resetting your credentials\n",
             "By doing:\n\n",
             "   Motus$userLogin = 'myusername'\n",
             "   Motus$userPassword = 'mypassword'\n"
             )
    }
}
