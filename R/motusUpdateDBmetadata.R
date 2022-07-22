#' update the metadata for receivers and tags in a motus tag detection database
#'
#' @param src SQLite Connection
#' @param tagIDs integer vector of tag IDs for which metadata should be
#'   obtained; default: NULL, meaning obtain metadata for all tags with
#'   detections in the database.  Negative values represent proxy tags for
#'   groups of ambiguous real tags, and if present in \code{tagIDs} the groups
#'   represented by them are fetched and stored in the DB's \code{tagAmbig}
#'   table.
#' @param deviceIDs integer vector of device IDs for which metadata should be
#'   obtained; default: NULL, meaning obtain metadata for all receivers from
#'   which the database has detections
#' @param force logical scalar; if TRUE, re-obtain metadata even if we already
#'   have it.
#'
#' @seealso \code{\link{tagme}}, which is intended for most users, and
#'     indirectly calls this function.
#'     
#' @noRd

motusUpdateDBmetadata <- function(src, tagIDs = NULL, deviceIDs = NULL, force = FALSE) {
  check_src(src)
  
  if (is.null(tagIDs) | force) {
    tagIDs <- DBI_Query(src, "SELECT DISTINCT motusTagID FROM runs")
  }
  
  if (! force) {
    ## drop tags for which we already have metadata
    have <- DBI_Query(src, "SELECT DISTINCT tagID FROM tagDeps")
    tagIDs <- setdiff(tagIDs, have)
    
    ## drop ambiguous tags for which we already ave the mapping
    have <- DBI_Query(src, "SELECT DISTINCT ambigID FROM tagAmbig")
    tagIDs <- setdiff(tagIDs, have)
  }
  
  if (is.null(deviceIDs) | force) {
    deviceIDs <- DBI_Query(src, "SELECT DISTINCT motusDeviceID FROM batches")
  }
    
  if (! force) {
    have <- DBI_Query(src, "SELECT DISTINCT deviceID FROM recvDeps")
    deviceIDs <- setdiff(deviceIDs, have)
  }
  
  realTagIDs  <- tagIDs[tagIDs > 0]
  ambigTagIDs <- tagIDs[tagIDs < 0]
  
  ## get mappings for tag ambiguities
  if (length(ambigTagIDs) > 0) {
    ambig <- srvTagsForAmbiguities(tagIDs[tagIDs < 0])
    dbInsertOrReplace(src, "tagAmbig", ambig)
    
    ## augment the tagIDs we need metadata for by the ambiguous tags for each
    ## ambigTagID; these are stored in columns motusTagID1, motusTagID2, ...
    
    realTagIDs <- unique(c(realTagIDs, unlist(ambig[, grep("motusTagID", names(ambig))])))
    realTagIDs <- realTagIDs[! is.na(realTagIDs)]
  }
  
  ## get metadata for tags, their deployments, and species names
  if (length(realTagIDs) > 0) {
    tmeta <- srvMetadataForTags(motusTagIDs = realTagIDs)
    dbInsertOrReplace(src, "tags", tmeta$tags)
    dbInsertOrReplace(src, "tagDeps", tmeta$tagDeps)
    dbInsertOrReplace(src, "tagProps", tmeta$tagProps)
    dbInsertOrReplace(src, "species", tmeta$species)
    dbInsertOrReplace(src, "projs", tmeta$projs)
    ## update tagDeps.fullID
    DBI_Execute(
      src,
      "UPDATE tagDeps SET ",
      "  fullID = ( ",
      "    SELECT ", 
      "      printf('%s#%s:%.1f@%g(M.%d)', t3.label, t2.mfgID, t2.bi, t2.nomFreq, t2.tagID) ",
      "    FROM ",
      "      tags AS t2 ",
      "      JOIN projs AS t3 ON t3.id = tagDeps.projectID ",
      "    WHERE ",
      "      t2.tagID = tagDeps.tagID ",
      "    LIMIT 1",
      "  ) ")
  }
  
  ## get metadata for receivers and their antennas
  if (length(deviceIDs) > 0) {
    rmeta <- srvMetadataForReceivers(deviceIDs)
    dbInsertOrReplace(src, "recvDeps", rmeta$recvDeps)
    dbInsertOrReplace(src, "recvs", rmeta$recvDeps[,c("deviceID", "serno")])
    dbInsertOrReplace(src, "antDeps", rmeta$antDeps)
    dbInsertOrReplace(src, "projs", rmeta$projs)
  }
  
  invisible(NULL)
}
