#' get the list tables and field names for databases
#'
#' List of tables and field names for creating databases
#'
#'
#' @noRd

srvSchema = function(verbose = FALSE) {
  x = srvQuery(API = motus_vars$API_SCHEMA, verbose = verbose)
  return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
