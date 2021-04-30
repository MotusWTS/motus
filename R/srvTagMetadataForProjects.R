#' get the tag metadata for some projects
#'
#' The basic tag and deployment metadata are returned for any
#' deployments the user has project permissions to, or which have
#' made their tag metadata public.
#'
#' @param projectIDs integer vector of motus project IDs
#'
#' @return a list with these items:
#' \itemize{
#' \item tags; a data.frame with these columns:
#' \itemize{
#' \item tagID; integer tag ID
#' \item projectID; integer motus ID of project that registered the tag
#' \item mfgID; character manufacturer tag ID
#' \item type; character  "ID" or "BEEPER"
#' \item codeSet; character e.g. "Lotek3", "Lotek4"
#' \item manufacturer; character e.g. "Lotek"
#' \item model; character e.g. "NTQB-3-1"
#' \item lifeSpan; integer estimated tag lifeSpan, in days
#' \item nomFreq; numeric nominal frequency of tag, in MHz
#' \item offsetFreq; numeric estimated offset frequency of tag, in kHz
#' \item bi; numeric burst interval or period of tag, in seconds
#' \item pulseLen; numeric length of tag pulses, in ms (not applicable to all tags)
#' }
#' \item tagDeps; a list with these columns:
#' \itemize{
#' \item tagID; integer motus tagID
#' \item deployID; integer tag deployment ID (internal to motus)
#' \item projectID; integer motus ID of project that deployed the tag
#' \item tsStart; numeric timestamp of start of deployment
#' \item tsEnd; numeric timestamp of end of deployment
#' \item deferSec; integer deferred activation period, in seconds (0 for most tags).
#' \item speciesID; integer motus species ID code
#' \item markerType; character type of marker on organism; e.g. leg band
#' \item markerNumber; character details of marker; e.g. leg band code
#' \item latitude; numeric deployment location, degrees N (negative is S)
#' \item longitude; numeric deployment location, degrees E (negative is W)
#' \item elevation; numeric deployment location, metres ASL
#' \item comments; character possibly JSON-formatted list of additional metadata
#' }
#' \item tagProps; a list with these columns:
#' \itemize{
#' \item tagID; integer motus tagID
#' \item deployID; integer tag deployment ID (internal to motus)
#' \item propID; integer property ID 
#' \item propName; character name of the custom property value provided by the user
#' \item propValue; character value of the custom property provided by the user
#' }
#' \item species; a list with these columns:
#' \itemize{
#' \item id; integer species ID,
#' \item english; character; English species name
#' \item french; character; French species name
#' \item scientific; character; scientific species name
#' \item group; character; higher-level taxon
#' }
#' \item projs; a list with these columns:
#' \itemize{
#' \item id; integer motus project id
#' \item name; character full name of motus project
#' \item label; character short label for motus project; e.g. for use in plots
#' }
#' }
#'
#' @noRd

srvTagMetadataForProjects <- function(projectIDs, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_TAG_METADATA_FOR_PROJECTS, 
               params = list(projectIDs = I(projectIDs)),
               verbose = verbose)
  list(
    tags = structure(x$tags, class = "data.frame", row.names=seq(along=x$tags[[1]])),
    tagDeps = structure(x$tagDeps, class = "data.frame", row.names=seq(along=x$tagDeps[[1]])),
    tagProps = structure(x$tagProps, class = "data.frame", row.names=seq(along=x$tagProps[[1]])),
    species = structure(x$species, class = "data.frame", row.names=seq(along=x$species[[1]])),
    projs = structure(x$projs, class = "data.frame", row.names=seq(along=x$projs[[1]]))
  )
}
