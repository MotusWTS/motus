#' Return filterID matching a filter name
#' 
#' Returns the filterID matching a filter name (and optionally a project ID)
#' If no project ID is specified and there is only 1 filter of the correct name,
#' return the filterID regardless of the project it is attached to.
#' If a project ID is specified or there are more than 1 filters of the name,
#' return the specific one matching the project ID (including NA). 
#'
#' @param src dplyr sqlite src, as returned by \code{dplyr::src_sqlite()}
#' @param filterName unique name given to the filter
#' @param motusProjID optional project ID attached to the filter in order to
#'   share with other users of the same project.
#'
#' @return an integer filterID
#'
#' @noRd

getRunsFilterID <- function(src, filterName, motusProjID = NA) {

  sqlq = function(...) DBI::dbGetQuery(src$con, sprintf(...))

  filterID <- NA
  
  # if motusProjID is not specified, look for the filter name across all projects 
  if (is.na(motusProjID)) {
    motusProjID = -1
    df = sqlq("select * from filters where filterName = '%s'", filterName)
    if (nrow(df) == 0) {
      warning("There are no filter matching this name.", call. = FALSE)
    } else if (nrow(df) == 1) {
      filterID <- df[1, ]$filterID
    }
  } else {
    # if a project is specified, or there are more than 1 matching name, 
    # limit the search to a specific project (including filters unassigned to a project = -1)
    # by default, return the filter not attached to a project
    df = sqlq("select * from filters where filterName = '%s' and motusProjID = %d", filterName, motusProjID)
    if (nrow(df) == 0) {
      warning("There are no filter matching this name.", call. = FALSE)
    } else if (nrow(df) == 1) {
      filterID <- df[1,]$filterID
    } else {
      warning("There are more than 1 existing filters matching your request.", 
              call. = FALSE)
    }    
  }  
  
  filterID
}