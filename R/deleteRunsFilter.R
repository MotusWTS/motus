#' Delete a filter  matching a filter name (and optionally a project ID)
#'
#' @param src SQLite connection (result of `tagme(XXX)` or
#'   `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`)
#'
#' @param filterName unique name given to the filter 
#'
#' @param motusProjID optional project ID attached to the filter in order to share with other users of the same project.
#'
#' @param clearOnly boolean. When true, only remove the probability records associated with the filter, 
#' but retain the filter itself
#'
#' @return the integer filterID of the filter deleted
#'
#' @export

deleteRunsFilter <- function(src, filterName, motusProjID = NA, clearOnly = FALSE) {

  # determines the filterID
  filterID <- getRunsFilterID(src, filterName, motusProjID)
  
  if (!is.null(filterID)) {
    DBI_Execute("DELETE FROM runsFilters WHERE filterID = {'filterID'}")
    if (!clearOnly) DBI_Execute("DELETE FROM filters WHERE filterID = {'filterID'}")
  }
  
  filterID
}