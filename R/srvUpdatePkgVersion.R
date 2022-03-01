#' Update the motus package version stored on the server
#'
#' @param version R version to consider 'current'
#'
#' @noRd

srvUpdatePkgVersion <- function(version, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_UPDATE_PKG_VERSION, 
                params = list(pkgVersion = I(version)), 
                verbose = verbose)
}
