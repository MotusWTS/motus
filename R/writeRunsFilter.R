#' Write to the local database the probabilities associated with runs for a filter
#'
#' @param src dplyr sqlite src, as returned by \code{dplyr::src_sqlite()}
#'
#' @param filterName unique name given to the filter 
#'
#' @param motusProjID optional project ID attached to the filter in order to share with other users of the same project.
#'
#' @param df dataframe containing the runID, the motusTagID and probability values to save in the local database
#'
#' @param overwrite boolean. When TRUE ensures that existing records matching the same filterName 
#' and runID get replaced
#'
#' @param delete boolean. When TRUE, removes all existing filter records associated with the filterName 
#' and re-inserts the ones contained in the dataframe. This option should be used if the dataframe 
#' provided contains the entire set of filters you want to save.
#'
#' @return a dplyr sqlite object refering to the filter created
#'
#' @export

writeRunsFilter = function(src, filterName, motusProjID=NA, df, overwrite=TRUE, delete=FALSE) {

  sql = function(...) DBI::dbExecute(src$con, sprintf(...))
  
  # determines the filterID
  id = createRunsFilter(src, filterName, motusProjID, update=FALSE)
    
  if (!is.null(id)) {
    if (delete) {
      deleteRunsFilter(src, filterName, motusProjID, clearOnly = TRUE)
    }
    df$filterID = id

    dbInsertOrReplace(src$con, "runsFilters", df, replace=overwrite)
    message("Filter records saved");
  
  }
 
  return(dplyr::tbl(src, "runsFilters") %>% dplyr::filter(.data$filterID == id))

}