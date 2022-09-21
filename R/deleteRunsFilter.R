#' Delete a filter
#' 
#' Deletes a filter by name or project ID.
#'
#' @param clearOnly Logical. When true, only remove the probability records
#'   associated with the filter, but retain the filter itself
#'
#' @inheritParams args
#'
#' @return the integer `filterID` of the filter deleted
#'
#' @export

deleteRunsFilter <- function(src, filterName, motusProjID = NA, clearOnly = FALSE) {

  # determines the filterID
  filterID <- getRunsFilterID(src, filterName, motusProjID)
  
  if (!is.null(filterID)) {
    DBI_Execute(src, "DELETE FROM runsFilters WHERE filterID = {filterID}")
    if (!clearOnly) DBI_Execute(src, "DELETE FROM filters WHERE filterID = {filterID}")
  }
  
  filterID
}