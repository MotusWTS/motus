#' get the metadata for some receivers
#'
#' The receiver and antenna metadata are returned for any deployments
#' of the specified devices for which the user has project permissions
#' to, or which have made their receiver metadata public.
#'
#' @param deviceIDs integer vector of motus receiver IDs
#'
#' @return a list with these items:
#' \itemize{
#'    \item recvDeps; a data.frame with these columns:
#'    \itemize{
#'       \item deployID; integer deployment ID (internal to motus, but links to antDeps)
#'       \item projectID; integer ID of project that deployed the receiver
#'       \item serno; character serial number, e.g. "SG-1214BBBK3999", "Lotek-8681"
#'       \item receiverType; character "SENSORGNOME" or "LOTEK"
#'       \item deviceID; integer device ID (internal to motus)
#'       \item status; character deployment status
#'       \item name; character; typically a site name
#'       \item fixtureType; character; what is the receiver mounted on?
#'       \item latitude; numeric (initial) location, degrees North
#'       \item longitude; numeric (initial) location, degrees East
#'       \item elevation; numeric (initial) location, metres ASL
#'       \item isMobile; integer non-zero means a mobile deployment
#'       \item tsStart; numeric; timestamp of deployment start
#'       \item tsEnd; numeric; timestamp of deployment end, or NA if ongoing
#'    }
#'    \item antDeps; a data.frame with these columns:
#'    \itemize{
#'       \item deployID; integer, links to deployID in recvDeps table
#'       \item port; integer, which receiver port (USB for SGs, BNC for Lotek) the antenna is connected to
#'       \item antennaType; character; e.g. "Yagi-5", "omni"
#'       \item bearing; numeric compass angle at which antenna is pointing; degrees clockwise from magnetic north
#'       \item heightMeters; numeric height of main antenna element above ground
#'       \item cableLengthMeters; numeric length of coaxial cable from antenna to receiver, in metres
#'       \item cableType: character; type of cable; e.g. "RG-58"
#'       \item mountDistanceMeters; numeric distance of mounting point from receiver, in metres
#'       \item mountBearing; numeric compass angle from receiver to antenna mount; degrees clockwise from magnetic north
#'       \item polarization2; numeric angle giving tilt from "normal" position, in degrees
#'       \item polarization1; numeric angle giving rotation of antenna about own axis, in degrees.
#'    }
#'    \item projs; a list with these columns:
#'    \itemize{
#'       \item id; integer motus project id
#'       \item name; character full name of motus project
#'       \item label; character short label for motus project; e.g. for use in plots
#'    }
#' }
#'
#' @noRd

srvMetadataForReceivers <- function(deviceIDs, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_METADATA_FOR_RECEIVERS, 
                params = list(deviceIDs = I(deviceIDs)),
                verbose = verbose)
  list(
    recvDeps = structure(x$recvDeps, class = "data.frame", row.names=seq(along=x$recvDeps[[1]])),
    antDeps = structure(x$antDeps, class = "data.frame", row.names=seq(along=x$antDeps[[1]])),
    projs = structure(x$projs, class = "data.frame", row.names=seq(along=x$projs[[1]]))
  )
}
