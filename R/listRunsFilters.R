#' Returns a dataframe of the filters stored in the local database. 
#'
#' @param src SQLite connection (result of `tagme(XXX)` or
#'   `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`)
#'
#' @return a dataframe 
#'
#' @export

listRunsFilters = function(src) {
  
  sqlq = function(...) DBI::dbGetQuery(src, sprintf(...))
  
  return (sqlq("select * from filters"))
  
}