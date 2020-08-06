#' Create a new filter records that can be applied to runs
#'
#' @param src dplyr sqlite src, as returned by \code{dplyr::src_sqlite()}
#'
#' @param filterName unique name given to the filter 
#'
#' @param motusProjID optional project ID attached to the filter in order to share with other users of the same project.
#'
#' @param descr optional filter description detailing what the filter is meant to do
#'
#' @param update whether the filter record gets updated when a filter with the same name already exists.
#'
#' @return an integer filterID
#'
#' @export

createRunsFilter = function(src, filterName, motusProjID=NA, descr=NA, update=FALSE) {

  sqlq = function(...) DBI::dbGetQuery(src$con, sprintf(...))

  if (is.na(motusProjID)) motusProjID = -1
  
  df = sqlq("select * from filters where filterName = '%s' and motusProjID = %d", filterName, motusProjID)
  if (nrow(df) == 0) {
    df = data.frame(userLogin=motus_vars$userLogin, filterName=filterName, motusProjID=motusProjID, descr=descr, lastModified=format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
    dbInsertOrReplace(src$con, "filters", df)
    df = sqlq("select * from filters where filterName = '%s' and motusProjID = %d", filterName, motusProjID)
    return (df[1,]$filterID)
  } else if (nrow(df) == 1) {
    if (update) {
		  df$descr = descr
		  df$lastModified=format(Sys.time(), "%Y-%m-%d %H:%M:%S")
		  dbInsertOrReplace(src$con, "filters", df);
		  warning("Filter already exists. The description has been updated.")	
	  } else {
	  	warning("Warning: filter already exists. Use createRunsFilter function with update=TRUE if you want to update the properties (e.g. name) of the existing filter.")	
  	}
    return (df[1,]$filterID)
    
  } else {
    warning("There are more than 1 existing filters matching your request.")
    return()
  }
 
}