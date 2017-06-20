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
#' @seealso \link{\code{tagme}}, which is intended for most users, and calls this function.
#'
#' @note This function does most of the work of fetching data and metadata from
#' motus servers.  It is not really meant to be called directly by most users.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusUpdateDB = function(projRecv, src, countOnly) {
    if (! is.numeric(projRecv) && ! is.character(projRecv))
        stop ("projRecv must be an integer motus project ID, or a character receiver serial number")

    if (! inherits(src, "dplyr::src_sqlite"))
        stop ("src must be a dplyr::src_sqlite object")

    if (!is.logical(countOnly))
        stop("countOnly must be a logical scalar")

    sql = safeSQL(src)

    if (is.numeric(projRecv))
        return(motusUpdateRecvDB(sql, countOnly))
    else
        return(motusUpdateProjDB(sql, countOnly))
}
