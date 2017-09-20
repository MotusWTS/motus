#' update a motus tag detection database - tag flavour (backend)
#'
#' @param src src_sqlite object representing the database
#'
#' @param countOnly logical scalar: count results instead of returning them?
#'
#' @param forceMeta logical scalar: if true, re-get metadata for tags and
#' receivers, even if we already have them.  Default:  FALSE.
#'
#' @return \code{src}, if countOnly is FALSE.  Otherwise, a list
#' of counts items that would be transferred by the update.
#'
#' @seealso \link{\code{tagme}}, which is intended for most users, and
#'     indirectly calls this function.
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusUpdateTagDB = function(src, countOnly=FALSE, forceMeta=FALSE) {
    sql = safeSQL(src)

    projectID = sql("select val from meta where key='tagProject'")[[1]] %>% as.integer

    batchID = sql("select ifnull(max(batchID), 0) from batches")[[1]]
    if (countOnly)
        return (srvSizeOfUpdateForTagProject(projectID=projectID, batchID=batchID))

    ## keep track of items we'll need metadata for
    tagIDs = c()
    devIDs = c()

    ## ----------------------------------------------------------------------------
    ## 1. get records for all new batches
    ## Start after the latest batch we already have.
    ## ----------------------------------------------------------------------------

    repeat {
        ## we always use countOnly = FALSE, because we need to obtain batchIDs
        ## in order to count runs and hits
        b = srvBatchesForTagProject(projectID=projectID, batchID=batchID)
        if (! isTRUE(nrow(b) > 0))
            break
        ## temporary work-around to batches with incorrect starting timestamps
        ## (e.g. negative, or on CLOCK_MONOTONIC) that make a batch appears
        ## to span multiple deployments.
        b = subset(b, ! duplicated(batchID))

        devIDs = unique(c(devIDs, b$motusDeviceID))
        cat(sprintf("Got %d batch records\n", nrow(b)), file=stderr())
        for (bi in 1:nrow(b)) {
            batchID = b$batchID[bi]
            batchMsg = sprintf("batchID %8d (#%6d of %6d)", batchID, bi, nrow(b))
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

                r = srvRunsForTagProject(projectID=projectID, batchID=batchID, runID=runID)
                if (! isTRUE(nrow(r) > 0))
                    break

                tagIDs = unique(c(tagIDs, r$motusTagID))
                ## add these run records to the DB
                ## Because some might be updates, or a previous transfer might have been
                ## interrupted, use dbInsertOrReplace

                dbInsertOrReplace(sql$con, "runs", r)
                dbWriteTable(sql$con, "batchRuns", data.frame(batchID=batchID, runID=r$runID), append=TRUE, row.names=FALSE)
                cat(sprintf("%s: got %6d runs starting at %15.0f\r", batchMsg, nrow(r), runID), file=stderr())
                runID = max(r$runID)
            }

            ## ----------------------------------------------------------------------------
            ## 3. get hits for one new batch
            ## Start after the largest hitID we already have.
            ## (also get the count of hits we already have for this batch, to which we'll add
            ## new hits as we get them, writing the final total to the numHits field in
            ## this batch's record).
            ## ----------------------------------------------------------------------------

            nn = sql("select ifnull(max(hitID), 0), count(*) from hits where batchID=%d", batchID)
            hitID = nn[[1]]
            numHits = nn[[2]]
            repeat {
                h = srvHitsForTagProject(projectID=projectID, batchID=batchID, hitID=hitID)
                if (! isTRUE(nrow(h) > 0))
                    break
                cat(sprintf("%s: got %6d hits starting at %15.0f\r", batchMsg, nrow(h), hitID), file=stderr())
                ## add these hit records to the DB
                dbWriteTable(sql$con, "hits", h, append=TRUE, row.names=FALSE)
                numHits = numHits + nrow(h)
                hitID = max(h$hitID)
            }

            ## ----------------------------------------------------------------------------
            ## 4. get GPS fixes for this batch
            ## Start after the largest TS for which we already have a fix
            ## ----------------------------------------------------------------------------

            ts = sql("select ifnull(max(ts), 0) from gps where batchID=%d", batchID)[[1]]
            repeat {
                g = srvGPSforTagProject(projectID=projectID, batchID=batchID, ts=ts)
                if (! isTRUE(nrow(g) > 0))
                    break
                cat(sprintf("%s: got %6d GPS fixes                     \r", batchMsg, nrow(g)), file=stderr())
                dbInsertOrReplace(sql$con, "gps", g[, c("batchID", "ts", "gpsts", "lat", "lon", "alt")])
                ts = max(g$ts)
            }

            ## ----------------------------------------------------------------------------
            ## 5. write the record for this batch
            ## This marks the transfers for this batch as complete.
            ## ----------------------------------------------------------------------------

            ## update the number of hits; this won't necessarily be
            ## the same value as supplied by the server, since our
            ## copy of this batch has only the hits from tags in this
            ## project, whereas the server's has hits from all
            ## projects's tags.

            b$numHits[bi] = numHits
            dbWriteTable(sql$con, "batches", b[bi,], append=TRUE, row.names=FALSE)
        }
        batchID = max(b$batchID)
    }
    motusUpdateDBmetadata(sql, tagIDs, devIDs, force=forceMeta)
    return(src)
}
