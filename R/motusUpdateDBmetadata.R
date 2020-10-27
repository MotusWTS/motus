#' update the metadata for receivers and tags in a motus tag detection database
#'
#' @param sql safeSQL object representing the tag project database
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

motusUpdateDBmetadata = function(sql, tagIDs=NULL, deviceIDs=NULL, force=FALSE) {
    if (!inherits(sql, "safeSQL"))
        stop("sql must be a database connection of type 'safeSQL'.\n",
             "Perhaps use tagme() instead of this function?", call. = FALSE)

    if (is.null(tagIDs))
        tagIDs = sql("select distinct motusTagID from runs")[[1]]

    if (! force) {
        ## drop tags for which we already have metadata
        have = sql("select distinct tagID from tagDeps")[[1]]
        tagIDs = setdiff(tagIDs, have)

        ## drop ambiguous tags for which we already ave the mapping
        have = sql("select distinct ambigID from tagAmbig")[[1]]
        tagIDs = setdiff(tagIDs, have)
    }

    if (is.null(deviceIDs))
        deviceIDs = sql("select distinct motusDeviceID from batches")[[1]]

    if (! force) {
        have = sql("select distinct deviceID from recvDeps")[[1]]
        deviceIDs = setdiff(deviceIDs, have)
    }

    realTagIDs  = tagIDs[tagIDs > 0]
    ambigTagIDs = tagIDs[tagIDs < 0]

    ## get mappings for tag ambiguities
    if (length(ambigTagIDs) > 0) {
        ambig = srvTagsForAmbiguities(tagIDs[tagIDs < 0])
        dbInsertOrReplace(sql$con, "tagAmbig", ambig)

        ## augment the tagIDs we need metadata for by the ambiguous tags for each
        ## ambigTagID; these are stored in columns motusTagID1, motusTagID2, ...

        realTagIDs = unique(c(realTagIDs, unlist(ambig[, grep("motusTagID", names(ambig))])))
        realTagIDs = realTagIDs[! is.na(realTagIDs)]
    }

    ## get metadata for tags, their deployments, and species names
    if (length(realTagIDs) > 0) {
        tmeta = srvMetadataForTags(motusTagIDs=realTagIDs)
        dbInsertOrReplace(sql$con, "tags", tmeta$tags)
        dbInsertOrReplace(sql$con, "tagDeps", tmeta$tagDeps)
        dbInsertOrReplace(sql$con, "tagProps", tmeta$tagProps)
        dbInsertOrReplace(sql$con, "species", tmeta$species)
        dbInsertOrReplace(sql$con, "projs", tmeta$projs)
        ## update tagDeps.fullID
        sql("
update
   tagDeps
set
   fullID = (
      select
         printf('%s#%s:%.1f@%g(M.%d)', t3.label, t2.mfgID, t2.bi, t2.nomFreq, t2.tagID)
      from
         tags as t2
         join projs as t3 on t3.id = tagDeps.projectID
      where
         t2.tagID = tagDeps.tagID
      limit 1
   )
")
    }

    ## get metadata for receivers and their antennas
    if (length(deviceIDs) > 0) {
        rmeta = srvMetadataForReceivers(deviceIDs)
        dbInsertOrReplace(sql$con, "recvDeps", rmeta$recvDeps)
        dbInsertOrReplace(sql$con, "recvs", rmeta$recvDeps[,c("deviceID", "serno")])
        dbInsertOrReplace(sql$con, "antDeps", rmeta$antDeps)
        dbInsertOrReplace(sql$con, "projs", rmeta$projs)
    }
    rv = invisible(NULL)
    return(rv)
}
