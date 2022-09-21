#' Get runsFilters
#' 
#' Returns a dataframe of the `runsFilters` records matching a filter name (and
#' optionally a project ID) stored in the local database.
#'
#' @inheritParams args
#' 
#' @return a database connection to `src`
#'
#' @export

getRunsFilters <- function(src, filterName, motusProjID = NA) {
  
  id <- getRunsFilterID(src, filterName, motusProjID)
  if (!is.null(id)) {
    id <- dplyr::tbl(src, "runsFilters") %>% 
      dplyr::filter(.data$filterID == id)
  }
  id
}