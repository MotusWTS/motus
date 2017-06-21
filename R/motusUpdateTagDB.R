#' update a motus tag detection database - tag flavour (backend)
#'
#' @param sql safeSQL object representing the tag project database
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

motusUpdateTagDB = function(sql, countOnly=FALSE) {
    if (!inherits(sql, "safeSQL"))
        stop("sql must be a database connection of type 'safeSQL'.\nPerhaps use tagme() instead of this function?")
    projectID = sql("select val from meta where key='tagProject'")[[1]]

    ## keep track of items we'll need metadata for
    tagIDs = c()
    devIDs = c()

    ## counts of items
    numBatches = numRuns = numHits = 0

    ## ----------------------------------------------------------------------------
    ## 1. get records for all new batches
    ## Start after the latest batch we already have.
    ## ----------------------------------------------------------------------------

    ts = sql("select max(ts) from batches")
    if (! is.finite(ts))
        ts = 0
    repeat {
        ## we always use countOnly = FALSE, because we need to obtain batchIDs
        ## in order to count runs and hits
        b = srvBatchesForTagProject(projectID=projectID, ts=ts, countOnly=FALSE)
        if (nrow(b) == 0)
            break
        ## temporary work-around to batches with incorrect starting timestamps
        ## (e.g. negative, or on CLOCK_MONOTONIC) that make a batch appears
        ## to span multiple deployments.
        b = subset(b, ! duplicated(batchID))
        numBatches = numBatches + if (countOnly) b else nrow(b)

        devIDs = unique(c(devIDs, b$motusDeviceID))
        cat(sprintf("Got %d batch records\n", nrow(b)), file=stderr())
        for (bi in 1:nrow(b)) {
            batchID = b$batchID[bi]
            ## To handle interruption of transfers, we save a record to the batches
            ## table as the last step after acquiring runs and hits for that batch.

            ## ----------------------------------------------------------------------------
            ## 2. get runs for one new batch
            ## Start with runID = 0, because we don't know in advance what
            ## runs that we already have records for might be modified by
            ## each batch
            ## ----------------------------------------------------------------------------
            runID = 0
            repeat {

                r = srvRunsForTagProject(projectID=projectID, batchID=batchID, runID=runID, countOnly=countOnly)
                if (countOnly) {
                    if (r == 0)
                        break
                    numRuns = num
                    if (&& r == 0) || (! countOnly && nrow(r) == 0))
                    break

                numRuns = numRuns + nrow(r)
                tagIDs = unique(c(tagIDs, r$motusTagID))
                ## add these run records to the DB
                ## Because some might be updates, or a previous transfer might have been
                ## interrupted, use dbInsertOrReplace

                dbInsertOrReplace(sql$con, "runs", r)
                cat(sprintf("Got %d runs from batch %d                \r", nrow(r), b), file=stderr())
                runID = max(r$runID)
            }

            ## ----------------------------------------------------------------------------
            ## 3. get hits for one new batch
            ## Start after the largest hitID we already have
            ## ----------------------------------------------------------------------------

            hitID = sql("select max(hitID) from hits where batchID=%d", b)
            repeat {
                h = srvHitsForTagProject(projectID=projectID, batchID=batchID, hitID=hitID, countOnly=countOnly)
                if (nrow(h) == 0)
                    break
                numHits = numHits + nrow(h)
                cat(sprintf("Got %d hits for batch %b                \r", nrow(h), b), file=stderr())
                ## add these hit records to the DB
                ## Because a previous transfer might have been
                ## interrupted, use dbInsertOrReplace
                dbInsertOrReplace(sql$con, "hits", h)
                hitID = max(h$hitID)
            }

            ## ----------------------------------------------------------------------------
            ## 4. get GPS fixes for this batch
            ## Start after the largest TS for which we already have a fix
            ## ----------------------------------------------------------------------------

            ts = sql("select max(ts) from gps where batchID=%d", batchID)
            repeat {
                g = srvGPSforTagProject(projectID=projectID, batchID=batchID, ts=ts)
                if (nrow(g) == 0)
                    break
                cat(sprintf("Got %d GPS fixes for batch %b                \r", nrow(g), b), file=stderr())
                dbInsertOrReplace(sql$con, "gps", g)
                ts = max(g$ts)
            }

            ## ----------------------------------------------------------------------------
            ## 5. write the record for this batch
            ## This marks the transfers for this batch as complete.
            ## ----------------------------------------------------------------------------

            dbWriteTable(sql$con, "batches", b[bi,], append=TRUE, row.names=FALSE)
        }
        ts = max(b$ts)
    }

    ## ----------------------------------------------------------------------------
    ## 6. get metadata for tags, their deployments, and species names
    ## ----------------------------------------------------------------------------

    tmeta = srvMetadataForTags(projectID=projectID, motusTagIDs=tagIDs[tagIDs > 0])
    dbInsertOrReplace(sql$con, "tags", tmeta$tags)
    dbInsertOrReplace(sql$con, "tagDeps", tmeta$tagDeps)
    dbInsertOrReplace(sql$con, "species", tmeta$species)

    ## ----------------------------------------------------------------------------
    ## 7. get metadata for tag ambiguities
    ## ----------------------------------------------------------------------------

    ambig = srvTagsForAmbiguities(tagIDs[tagIDs < 0])
    dbInsertOrReplace(sql$con, "tagAmbig", ambig)

    ## ----------------------------------------------------------------------------
    ## 8. get metadata for receivers and their antennas
    ## ----------------------------------------------------------------------------

    rmeta = srvMetadataForReceivers(devIDs)
    dbInsertOrReplace(sql$con, "recvDeps", rmeta$recvDeps)
    dbInsertOrReplace(sql$con, "antDeps", rmeta$antDeps)
}
