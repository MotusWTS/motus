#' Get the list tables and field names for databases
#'
#' List of tables and field names for creating databases
#'
#' @noRd

srvSchema <- function(verbose = FALSE) {
  srvQuery(API = motus_vars$API_SCHEMA, verbose = verbose) %>%
    to_df()
}
