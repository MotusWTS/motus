#' update the metadata for receivers and tags in a motus tag detection database
#'
#' @param sql safeSQL object representing the tag project database
#'
#' @param tagIDs integer vector of tag IDs for which metadata should
#' be obtained; default: NULL, meaning obtain metadata for all tags
#' with detections in the database.  Negative values represent
#' proxy tags for groups of ambiguous real tags, and if present in \code{tagIDs}
#' the groups represented by them are fetched and stored in the DB's
#' \code{tagAmbig} table.
#'
#' @param deviceIDs integer vector of device IDs for which metadata
#' should be obtained; default: NULL, meaning obtain metadata for all
#' receivers from which the database has detections
#'
#' @seealso \link{\code{tagme}}, which is intended for most users, and
#'     indirectly calls this function.
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusUpdateDBmetadata = function(sql, tagIDs=NULL, deviceIDs=NULL) {
    if (!inherits(sql, "safeSQL"))
        stop("sql must be a database connection of type 'safeSQL'.\nPerhaps use tagme() instead of this function?")

    if (is.null(tagIDs))
        tagIDs = sql("select distinct motusTagID from runs")[[1]]

    if (is.null(deviceIDs))
        deviceIDs = sql("select distinct motusDeviceID from batches")[[1]]

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
        dbInsertOrReplace(sql$con, "species", tmeta$species)
    }

    ## get metadata for receivers and their antennas
    if (length(deviceIDs) > 0) {
        rmeta = srvMetadataForReceivers(deviceIDs)
        dbInsertOrReplace(sql$con, "recvDeps", rmeta$recvDeps)
        dbInsertOrReplace(sql$con, "antDeps", rmeta$antDeps)
    }
    invisible(NULL)
}
