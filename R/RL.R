#' reload a function in a package from its source folder
#'
#' Not for final package distribution: this is a kludge to avoid having
#' to rebuild the whole package just to propagate a change in a single
#' function.
#'
#' @param f unquoted name of function
#'
#' @param path: path to source file containing new definition for \code{f};
#' Default is to run \code{find} starting at the user's home directory, looking
#' for a file called \code{paste0(substitute(f), ".R")}
#'
#' @param package: name of package to which \code{f} belongs.  Defaults to the
#' first package returned by \code{getAnywhere(f)}
#'
#' @details  Here's what \code{RL(f)} does:
#' \itemize{
#' \item the file \code{path} is sourced into
#' an empty environment \code{E}
#' \item for each symbol \code{S} in \code{E}:
#' \itemize{
#' \item if \code{S} is a function, set its binding environment to \code{namespace:PACKAGE}
#' \item unlock the binding for \code{S} in \code{namespace:PACKAGE}
#' \item bind \code{S} to \code{E$S} in \code{namespace:PACKAGE}
#' \item lock the binding for \code{S} in \code{namespace:PACKAGE}
#' \item if \code{S} is bound in \code{package:PACKAGE}:
#' \itemize{
#' \item unlock the binding for \code{S} in \code{package:PACKAGE}
#' \item bind \code{S} to \code{E$S} in \code{package:PACKAGE}
#' \item lock the binding for \code{S} in \code{package:PACKAGE}
#' }
#' }
#' }
#' where \code{PACKAGE} stands for the value of \code{package}.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

RL = function(f, path=NULL, package=NULL) {
    f = as.character(substitute(f))
    if (is.null(package))
        package=sub("^package:", "", grep("^package:", getAnywhere(f)$where, value=TRUE)[1])
    if (is.null(path))
        path = system(paste0("find ~ -path '*/", package, "/R/", f, ".R'"), intern=TRUE)
    e = new.env(emptyenv())
    zz = 90
    source(path, local=e, verbose=FALSE)
    nn = names(e)
    npackage = getNamespace(package)
    ppackage = as.environment(paste0("package:", package))
    for (n in nn) {
        if (is.function(e[[n]]))
            environment(e[[n]]) = npackage
        if (bindingIsLocked(n, npackage))
            unlockBinding(n, npackage)
        assign(n, e[[n]], npackage)
        lockBinding(n, npackage)
        if (exists(n, ppackage)) {
            unlockBinding(n, ppackage)
            assign(n, e[[n]], ppackage)
            lockBinding(n, ppackage)
        }
    }
}
