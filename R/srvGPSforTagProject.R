#' get the GPS fixes for a tag project from the data server
#'
#' These are the periodic GPS fixes from receivers that detected
#' tags from the project.
#'
#' @param projectID integer scalar motus tag project ID
#' @param batchID integer scalar batch ID
#' @param ts real scalar processing timestamp of latest fix already owned
#' Default: 0, meaning none.
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
#' @note: this returns fixes from receivers which detected tags from the
#' given project.  Fixes from up to 1 hour before to 1 hour after the
#' detections are included, to ensure temporal coverage.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvGPSforTagProject = function(projectID, batchID, ts=0) {
    x = srvQuery(API=Motus$API_GPS_FOR_TAG_PROJECT, params=list(projectID=projectID, batchID=batchID, ts=ts))
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
