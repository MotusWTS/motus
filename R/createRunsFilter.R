#' Create a new filter records that can be applied to runs
#'
#' @param descr Character. Optional filter description detailing what the filter
#'   is meant to do
#' @param update Logical. Whether the filter record gets updated when a filter
#'   with the same name already exists.
#'
#' @inheritParams args
#' 
#' @return an integer `filterID`
#'
#' @export

createRunsFilter <- function(src, filterName, motusProjID = NA, 
                             descr = NA, update = FALSE) {

  if (is.na(motusProjID)) motusProjID <- -1
  
  df <- DBI_Query(src, 
                  "SELECT * FROM filters WHERE filterName = {'filterName'} ",
                  "AND motusProjID = {motusProjID}")
  
  if (nrow(df) == 0) {
    df <- data.frame(userLogin = motus_vars$userLogin, 
                     filterName = filterName, 
                     motusProjID = motusProjID, 
                     descr = descr, 
                     lastModified = format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
    
    dbInsertOrReplace(src, "filters", df)
    
    df <- DBI_Query(src, 
                    "SELECT * FROM filters WHERE filterName = {'filterName'} ",
                    "AND motusProjID = {motusProjID}")
    
    return (df[1,]$filterID)
    
  } else if (nrow(df) == 1) {
    if (update) {
		  df$descr <- descr
		  df$lastModified <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
		  dbInsertOrReplace(src, "filters", df)
		  
		  warning("Filter already exists. The description has been updated.",
		          call. = FALSE)	
		  
	  } else {
	  	warning("Filter already exists. ",
	  	        "Use createRunsFilter function with 'update = TRUE' if you want ",
	  	        "to update the properties (e.g. name) of the existing filter.",
	  	        call. = FALSE)	
	  }
    
    return (df[1,]$filterID)
    
  } else {
    warning("There are more than 1 existing filters matching your request.",
            call. = FALSE)
    return()
  }
 
}