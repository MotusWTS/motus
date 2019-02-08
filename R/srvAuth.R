#' Authenticate with the data server.
#'
#' Use Motus$userLogin and Motus$userPassword to get an authentication
#' token from the data server.
#'
#' @return a character scalar authentication/authorization token
#'
#' @details if login is unsuccessful, execution stops with an error message
#'
#' @seealso \code{\link{Motus}}
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvAuth = function() {
    ## force lookup of userLogin and userPassword using their active bindings.
    ## (we don't want to use lazy evaluation here by instead passing the list(...)
    ## expression to srvQuery

    pars = list(user=Motus$userLogin, password=Motus$userPassword)
    tryCatch({
        res = srvQuery(Motus$API_DATA_AUTHENTICATE, pars, auth=FALSE)
        Motus$projects = res$projects
        ## cat(sprintf("Got authentication token from %s  \r",Motus$dataServerURL))
        return(res$authToken)
    }, error = function(e) {
        Motus$userLogin = NULL
        Motus$userPassword = NULL
        stop("The motus data server rejected your login credentials")
    })
}
