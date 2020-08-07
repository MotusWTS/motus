#' update a motus tag detection database - receiver flavour (backend)
#'
#' @param src src_sqlite object representing the database
#' @param countOnly logical scalar: count results instead of returning them?
#' @param forceMeta logical scalar: if true, re-get metadata for tags and
#'   receivers, even if we already have them.  Default: FALSE
#'
#' @return \code{src}, if countOnly is FALSE.  Otherwise, a list of
#'     counts items that would be transferred by the update.
#'
#' @seealso \code{\link{tagme}}, which is intended for most users, and
#'     indirectly calls this function.
#'     
#' @noRd

motusUpdateRecvDB <- function(src, countOnly, forceMeta=FALSE) {
    sql = safeSQL(src)
    
    recvSerno <- sql("select val from meta where key='recvSerno'")[[1]]
    deviceID <- sql("select val from meta where key='deviceID'")[[1]] %>% as.integer
    if (!isTRUE(deviceID > 0)) {
        stop("This receiver database does not have a valid deviceID stored in it.\n",
             "Try delete or rename the file and use tagme() again?", call. = FALSE)
    }
    batchID = sql("select ifnull(max(batchID), 0) from batches")[[1]]
    if (countOnly)
        return (srvSizeOfUpdateForReceiver(deviceID=deviceID, batchID=batchID))

    ## keep track of items we'll need metadata for
    tagIDs = c()

    ## ----------------------------------------------------------------------------
    ## 1. get records for all new batches
    ## Start after the latest batch we already have.
    ## ----------------------------------------------------------------------------
    message(paste0("Checking for new data for receiver ", recvSerno, 
                   " (deviceID: ", deviceID, ")"))
    repeat {
        ## we always use countOnly = FALSE, because we need to obtain batchIDs
        ## in order to count runs and hits
        b = srvBatchesForReceiver(deviceID=deviceID, batchID=batchID)
        if (! isTRUE(nrow(b) > 0))
            break
        ## temporary work-around to batches with incorrect starting timestamps
        ## (e.g. negative, or on CLOCK_MONOTONIC) that make a batch appears
        ## to span multiple deployments.
        b = subset(b, ! duplicated(batchID))

        message(sprintf("Receiver %s:  got %5d batch records", recvSerno, nrow(b)))
        for (bi in 1:nrow(b)) {
            batchID = b$batchID[bi]
            
            batchMsg <- sprintf("batchID %8d (#%6d of %6d)", batchID, bi, nrow(b))
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

                r = srvRunsForReceiver(batchID=batchID, runID=runID)
                if (! isTRUE(nrow(r) > 0))
                    break

                tagIDs = unique(c(tagIDs, r$motusTagID))
                ## add these run records to the DB
                ## Because some might be updates, or a previous transfer might have been
                ## interrupted, use dbInsertOrReplace

                dbInsertOrReplace(sql$con, "runs", r)
                DBI::dbWriteTable(sql$con, "batchRuns", 
                                  data.frame(batchID=batchID, runID=r$runID), 
                                  append=TRUE, row.names=FALSE)
                message(sprintf("%s: got %6d runs starting at %15.0f\r", 
                                batchMsg, nrow(r), runID))
                
                runID = max(r$runID)
            }

            ## ----------------------------------------------------------------------------
            ## 3. get hits for one new batch
            ## Start after the largest hitID we already have.
            ## (also get the count of hits we already have for this batch, to which we'll add
            ## new hits as we get them, writing the final total to the numHits field in
            ## this batch's record).
            ## ----------------------------------------------------------------------------

            hitID = sql("select ifnull(max(hitID), 0) from hits where batchID=%d", batchID)[[1]]
            repeat {
                h = srvHitsForReceiver(batchID=batchID, hitID=hitID)
                if (! isTRUE(nrow(h) > 0)) break
                message(sprintf("%s: got %6d hits starting at %15.0f\r", 
                                batchMsg, nrow(h), hitID))
                
                ## add these hit records to the DB
                DBI::dbWriteTable(sql$con, "hits", h, append=TRUE, row.names=FALSE)
                hitID = max(h$hitID)
            }

            ## ----------------------------------------------------------------------------
            ## 4. get GPS fixes for this batch
            ## Start after the largest TS for which we already have a fix
            ## ----------------------------------------------------------------------------

            ts = sql("select ifnull(max(ts), 0) from gps where batchID=%d", batchID)[[1]]
            repeat {
                g = srvGPSForReceiver(batchID=batchID, ts=ts)
                if (! isTRUE(nrow(g) > 0)) break
                message(sprintf("%s: got %6d GPS fixes                     \r", 
                                batchMsg, nrow(g)))
                dbInsertOrReplace(sql$con, "gps", g[, c("batchID", "ts", "gpsts", "lat", "lon", "alt")])
                ts = max(g$ts)
            }

            ## ----------------------------------------------------------------------------
            ## 5. get pulse counts for this batch
            ## Start after the largest ant, hourBin for which we already have pulseCounts
            ## from this batch.
            ## ----------------------------------------------------------------------------

            info = sql("select ant, hourBin from pulseCounts where batchID=%d order by ant desc, hourBin desc limit 1", batchID)
            if (nrow(info) == 1) {
                ant = info[[1]]
                hourBin = info[[2]]
            } else {
                ant = 0
                hourBin = 0
            }

            repeat {
                pc = srvPulseCountsforReceiver(batchID=batchID, ant=ant, hourBin=hourBin)
                if (! isTRUE(nrow(pc) > 0)) break
                message(sprintf("%s: got %6d pulse counts                     \r", 
                                batchMsg, nrow(pc)))
                dbInsertOrReplace(sql$con, "pulseCounts", pc[, c("batchID", "ant", "hourBin", "count")])
                ant = utils::tail(pc$ant, 1)
                hourBin = utils::tail(pc$hourBin, 1)
            }

            ## ----------------------------------------------------------------------------
            ## 6. write the record for this batch
            ## This marks the transfers for this batch as complete.
            ## ----------------------------------------------------------------------------

            ## update the number of hits; this won't necessarily be
            ## the same value as supplied by the server, since our
            ## copy of this batch has only the hits from tags in this
            ## project, whereas the server's has hits from all
            ## projects's tags.

            ## dbWriteTable(sql$con, "batches", b[bi,], append=TRUE, row.names=FALSE)
            dbInsertOrReplace(sql$con, "batches", b[bi,], replace=FALSE)
            
            # If testing, break out after x batches
            if(bi >= getOption("motus.test.max") && is_testing()) break
        }
        batchID = max(b$batchID)
    }

    motusUpdateDBmetadata(sql, tagIDs, deviceID, force=forceMeta)
    rv = src
    return(rv)
}
