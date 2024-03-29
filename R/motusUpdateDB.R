#' Update tag detection database
#' 
#'
#' @param projRecv integer scalar project code from motus.org, *or* character
#'   scalar receiver serial number
#' @param src SQLite Connection
#' @param countOnly Logical. If `FALSE`, the default, then do requested
#'   database updates.  Otherwise, return a count of items that would need to be
#'   transferred in order to update the database.
#' @param forceMeta Logical. If true, re-get metadata for tags and
#'   receivers, even if we already have them.
#'   
#' @return `src` if `countOnly` is `FALSE`.  Otherwise, a list of counts
#'   of items available for an update.
#'
#' @seealso `tagme()`, which is intended for most users, and calls this function.
#'
#' @note This function does most of the work of fetching data and metadata from
#'   motus servers.  It is not intended to be called directly by users.
#' 
#' @noRd

motusUpdateDB <- function(projRecv, src, countOnly, forceMeta = FALSE) {
  
  check_src(src)  
  
  if (! is.numeric(projRecv) && ! is.character(projRecv))
    stop("projRecv must be an integer motus project ID, ",
         "or a character receiver serial number", call. = FALSE)
  
  if (!is.logical(countOnly))
    stop("countOnly must be a logical scalar", call. = FALSE)
  
  if (is.numeric(projRecv)) {
    return(motusUpdateTagDB(src, countOnly, forceMeta))
  } else {
    return(motusUpdateRecvDB(src, countOnly, forceMeta))
  }
}
