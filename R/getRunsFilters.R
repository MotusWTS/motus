#' Returns a dataframe of the runFilters records matching a filter name (and optionally a project ID) stored 
#' in the local database. 
#'
#' @param src dplyr sqlite src, as returned by \code{dplyr::src_sqlite()}
#'
#' @param filterName unique name given to the filter 
#'
#' @param motusProjID optional project ID attached to the filter in order to share with other users of the 
#' same project.
#'
#' @return a dplyr sqlite object 
#'
#' @export
#'
#' @author Denis Lepage, Bird Studies Canada

getRunsFilters = function(src, filterName, motusProjID=NA) {
  
  id = getRunsFilterID(src, filterName, motusProjID)
  if (!is.null(id)) {
      return(tbl(src, "runsFilters") %>% filter(filterID == id))
  }
  return()
  
}