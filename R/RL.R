#' reload a function in this package from its source folder
#'
#' Not for final package distribution: this is a kludge to avoid having
#' to rebuild the whole package just to propagate a change in a single
#' function.
#'
#' @param f unquoted name of function
#'
#' @param path; path to source file containing new definition for \code{f};
#' default: \code{~/src/motus/R/f.R}
#'
#' @details  Here's what \code{RL(X)} does:
#' \itemize{
#' \item the file \code{path} is sourced into
#' an empty environment \code{E}
#' \item for each symbol \code{S} in \code{E}:
#' \itemize{
#' \item if \code{S} is a function, set its binding environment to \code{namespace:motusServer}
#' \item unlock the binding for \code{S} in \code{namespace:motusServer}
#' \item bind \code{S} to \code{E$S} in \code{namespace:motusServer}
#' \item lock the binding for \code{S} in \code{namespace:motusServer}
#' \item if \code{S} is bound in \code{package:motusServer}:
#' \itemize{
#' \item unlock the binding for \code{S} in \code{package:motusServer}
#' \item bind \code{S} to \code{E$S} in \code{package:motusServer}
#' \item lock the binding for \code{S} in \code{package:motusServer}
#' }
#' }
#' }
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}


RL = function(X, path=file.path("~/src/motus/R", paste0(substitute(X), ".R"))) {
   e = new.env(emptyenv())
   source(path, local=e, verbose=FALSE)
   nn = names(e)
   nmotus = getNamespace("motus")
   pmotus = as.environment("package:motus")
   for (n in nn) {
       if (is.function(e[[n]]))
           environment(e[[n]]) = nmotus
       if (bindingIsLocked(n, nmotus))
           unlockBinding(n, nmotus)
       assign(n, e[[n]], nmotus)
       lockBinding(n, nmotus)
       if (exists(n, pmotus)) {
           unlockBinding(n, pmotus)
           assign(n, e[[n]], pmotus)
           lockBinding(n, pmotus)
       }
   }
}
