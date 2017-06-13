#' get the GPS fixes for a receiver project from the data server
#'
#' These are the periodic GPS fixes from receivers belonging to the
#' project, and only makes sense for mobile receiver deployments.
#'
#' @param projectID integer scalar motus project ID
#' @param batchID integer scalar batch ID
#' @param ts real scalar processing timestamp of latest fix already owned
#' Default: 0, meaning none.
#' @param countOnly logical; if TRUE, return only the cound of available batches.
#' Default: FALSE.
#'
#' @return data.frame with these columns:
#' \itemize{
#'    \item ts       numeric system timestamp
#'    \item gpsts    numeric GPS timestamp
#'    \item batchID  integer batch ID
#'    \item lat      numeric latitude in degrees N (negative is south)
#'    \item lon      numeric longitude in degrees E (negative is west)
#'    \item alt      numeric altitude in metres ASL
#' }
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvGPSforReceiverProject = function(projectID, batchID, ts=0, countOnly=FALSE) {
    x = srvQuery(API=Motus$API_GPS_FOR_RECEIVER_PROJECT, params=list(projectID=projectID, batchID=batchID, ts=ts, countOnly=countOnly))
    if (countOnly)
        return (x$count)
    else
        return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
