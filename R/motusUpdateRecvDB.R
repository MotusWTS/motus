#' update a motus tag detection database - receiver flavour (backend)
#'
#' @param sql safeSQL object representing the receiver database
#'
#' @param countOnly logical scalar: if FALSE, the default, then do
#'     requested database updates.  Otherwise, return a count of items
#'     that would need to be transferred in order to update the
#'     database.
#'
#' @seealso \link{\code{tagme}}, which is intended for most users, and
#'     indirectly calls this function.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusUpdateRecvDB = function(sql, countOnly) {
    return(NULL)
}
