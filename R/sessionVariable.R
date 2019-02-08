#' Create a session variable in an environment.
#'
#' Session variables are typically only set once per R session.
#' They include items such as user login and password for motus.org
#' They are implemented as active bindings in an environment.  If the
#' binding's current value is NULL, the user is prompted to enter
#' the value.
#'
#' @param name name of variable
#'
#' @param info human-readable description of the variable. This is used
#' to prompt the user if the value of the variable is not already known.
#'
#' Alternatively, this can be an R function to be called the first time
#' the value needs to be obtained.  That function will presumably
#' depend on other session variables.  The function should return
#' the value of the variable (or generate an error if not successful).
#'
#' @param env environment in which to create the session variable
#' Default:  Motus
#'
#' @param class the class of the variable desired; when the user is
#' prompted for it, the value is coerced to this class.
#' Default: "character"
#'
#' @param val initial value of the session variable.  Default: unset.
#'
#' @return a function which can be installed as an active binding in an
#' environment
#'
#' @examples
#'
#'  sessionVariable("userLogin", "user login at motus.org")
#'
#' ## This creates an active binding for the symbol "userLogin" in the environment "Motus"
#' ## If the variable \code{Motus$userLogin} is requested in code, the user will
#' ## be prompted to enter a value if there is no current value.
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

sessionVariable = function(name, info=name, env=Motus, class="character", val=NULL) {
    getSet = function(val) {
        if ( ! missing(val)) {
            ## value supplied, so set it
            return(invisible(curVal <<- val))
        } else if (! is.null(curVal)) {
            ## value not supplied, but already assigned
            return (curVal)
        } else {
            ## value not supplied and not already assigned
            if (is.function(info)) {
                v = info()
            } else {
                cat("Please enter a value for ", info, "\n==> ", sep="")
                v = readLines(n=1)
            }
            if (isTRUE(nchar(v) > 0)) {
                ## set and return value
                return(curVal <<- as(v, class))
            }
            ## oops
            stop("session variable '", name, "' is undefined")
        }
    }
    e = new.env(emptyenv())
    e$curVal = val
    e$class = class
    e$info = info
    e$name = name
    environment(getSet) = e
    makeActiveBinding(name, getSet, env)
}
