#' get the list of receiver deployments for a project
#'
#' The metadata are returned for any deployments of a receiver
#' by the specified project, provided the user has permissions
#' to the project.
#'
#' @param projectID integer scalar motus project ID
#'
#' @return
#' a data.frame with these columns:
#' \itemize{
#'    \item projectID; integer ID of project that deployed the receiver
#'    \item serno; character serial number, e.g. "SG-1214BBBK3999", "Lotek-8681"
#'    \item receiverType; character "SENSORGNOME" or "LOTEK"
#'    \item deviceID; integer device ID (internal to motus)
#'    \item status; character deployment status
#'    \item name; character; typically a site name
#'    \item fixtureType; character; what is the receiver mounted on?
#'    \item latitude; numeric (initial) location, degrees North
#'    \item longitude; numeric (initial) location, degrees East
#'    \item elevation; numeric (initial) location, metres ASL
#'    \item isMobile; integer non-zero means a mobile deployment
#'    \item tsStart; numeric; timestamp of deployment start
#'    \item tsEnd; numeric; timestamp of deployment end, or NA if ongoing
#' }
#' and one row for each receiver deployment by project \code{projectID}
#'
#' @noRd

srvReceiversForProject = function(projectID, verbose = FALSE) {
    x = srvQuery(API=motus_vars$API_RECEIVERS_FOR_PROJECT, 
                 params=list(projectID=projectID), 
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
