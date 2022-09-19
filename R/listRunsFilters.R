#' Returns a dataframe of the filters stored in the local database. 
#'
#' @inheritParams args
#'
#' @return a dataframe 
#'
#' @export

listRunsFilters <- function(src) DBI_Query(src, "SELECT * FROM filters")