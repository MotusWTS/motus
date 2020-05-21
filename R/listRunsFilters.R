#' Returns a dataframe of the filters stored in the local database. 
#'
#' @param src dplyr sqlite src, as returned by \code{dplyr::src_sqlite()}
#'
#' @return a dataframe 
#'
#' @export

listRunsFilters = function(src) {
  
  sqlq = function(...) DBI::dbGetQuery(src$con, sprintf(...))
  
  return (sqlq("select * from filters"))
  
}