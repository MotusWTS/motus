#' update a motus tag detection database (backend)
#'
#' @param projRecv integer scalar project code from motus.org, *or*
#' character scalar receiver serial number
#'
#' @param src src_sqlite object representing the database
#'
#' @param countOnly logical scalar: if FALSE, the default, then do
#'     requested database updates.  Otherwise, return a count of items
#'     that would need to be transferred in order to update the
#'     database.
#'
#' @param forceMeta logical scalar: if true, re-get metadata for tags and
#' receivers, even if we already have them.
#'
#' @return \code{src} if \code{countOnly} is FALSE.  Otherwise, a list
#' of counts of items available for an update.
#'
#' @seealso \code{\link{tagme}}, which is intended for most users, and calls this function.
#'
#' @note This function does most of the work of fetching data and metadata from
#' motus servers.  It is not intended to be called directly by users.
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusUpdateDB = function(projRecv, src, countOnly, forceMeta=FALSE) {
    if (! is.numeric(projRecv) && ! is.character(projRecv))
        stop ("projRecv must be an integer motus project ID, or a character receiver serial number")

    if (! inherits(src, "src_sql"))
        stop ("src must be a dplyr::src_sql object")

    if (!is.logical(countOnly))
        stop("countOnly must be a logical scalar")

    if (is.numeric(projRecv))
        return(motusUpdateTagDB(src, countOnly, forceMeta))
    else
        return(motusUpdateRecvDB(src, countOnly, forceMeta))
}
