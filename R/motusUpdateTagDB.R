#' update a motus tag detection database - tag flavour (backend)
#'
#' @param src src_sqlite object representing the database
#' @param countOnly logical scalar: count results instead of returning them?
#' @param forceMeta logical scalar: if true, re-get metadata for tags and
#'   receivers, even if we already have them.  Default:  FALSE.
#'
#' @return \code{src}, if countOnly is FALSE.  Otherwise, a list
#' of counts items that would be transferred by the update.
#'
#' @seealso \code{\link{tagme}}, which is intended for most users, and
#'     indirectly calls this function.
#'
#' @noRd

motusUpdateTagDB <- function(src, countOnly = FALSE, forceMeta = FALSE) {
  sql <- safeSQL(src)
  
  projectID <- sql("select val from meta where key = 'tagProject'")[[1]] %>% 
    as.integer()
  
  batchID <- sql(paste0("select max(a.batchID) from projBatch a ",
                        "inner join batches b on a.batchID = b.batchID ",
                        "where tagDepProjectID = %d"), projectID)
  if(countOnly) {
    return(srvSizeOfUpdateForTagProject(projectID = projectID, 
                                        batchID = batchID))
  }

  ambigProjs <- srvProjectAmbiguitiesForTagProject(projectID)
  dbInsertOrReplace(src$con, "projAmbig", ambigProjs)
  projectIDs <- unique(c(projectID, ambigProjs$ambigProjectID))
  
  msg <- sprintf("Checking for new data in project %d", projectID)
  if (length(projectIDs) > 1) {
    msg <- paste0(msg, sprintf("\nand in ambiguous detection projects %s", 
                               paste(projectIDs[-1], collapse = ", ")))
  }
  message(msg)
  
  ## keep track of items we'll need metadata for
  tagIDs <- c()
  devIDs <- c()
  
  for (projectID in projectIDs) {
    batchID <- sql(paste0("select ifnull(max(a.batchID), 0) from projBatch a ",
                          "inner join batches b on a.batchID = b.batchID ",
                          "where tagDepProjectID = %d"), projectID)[[1]]
    
    ## ----------------------------------------------------------------------------
    ## 1. get records for all new batches
    ## Start after the latest batch we already have.
    ## ----------------------------------------------------------------------------

    # Batches -----------------------------------------------------------------
    
    repeat {
      ## we always use countOnly = FALSE, because we need to obtain batchIDs
      ## in order to count runs and hits
      b <- srvBatchesForTagProject(projectID = projectID, batchID = batchID)
      if (!isTRUE(nrow(b) > 0)) break

      # Check that version matches (just in case)
      if(any(b$version != dplyr::tbl(src$con, "admInfo") %>%
             dplyr::pull(.data$data_version))) {
        stop("Server data version doesn't match the version in this database",
             call. = FALSE)
      }
      
      ## temporary work-around to batches with incorrect starting timestamps
      ## (e.g. negative, or on CLOCK_MONOTONIC) that make a batch appears
      ## to span multiple deployments.
      b <- subset(b, !duplicated(batchID))
      
      devIDs <- unique(c(devIDs, b$motusDeviceID))
      message(sprintf("Project %5d:  got %5d batch records", projectID, nrow(b)))
      
      for (bi in 1:nrow(b)) {
        batchID <- b$batchID[bi]
        ## grab existing batch record, if any.  This will only return
        ## a non-empty result if we're currently grabbing data for a
        ## project with which the main project has an ambiguous tag.
        oldBatch <- sql("select * from batches where batchID = %d", batchID)
        batchMsg <- sprintf("batchID %8d (#%6d of %6d)", batchID, bi, nrow(b))
        
        ## To handle interruption of transfers, we save a record to the batches
        ## table as the last step after acquiring runs and hits for that batch.
        
        ## ----------------------------------------------------------------------------
        ## 2. get runs for one new batch
        ## Start with runID <- 0, because we don't know in advance what
        ## runs that we already have records for might be modified by
        ## each batch
        ## ----------------------------------------------------------------------------
        
        # Runs for Batch ------------------------------------------------------
        runID <- 0
        repeat {
          r <- srvRunsForTagProject(projectID = projectID, batchID = batchID, 
                                    runID = runID)
          
          if (!isTRUE(nrow(r) > 0)) break
          
          tagIDs <- unique(c(tagIDs, r$motusTagID))
          
          ## add these run records to the DB
          ## Because some might be updates, or a previous transfer might have been
          ## interrupted, use dbInsertOrReplace
          dbInsertOrReplace(sql$con, "runs", r)
          DBI::dbWriteTable(sql$con, "batchRuns", 
                            data.frame(batchID = batchID, runID = r$runID), 
                            append = TRUE, row.names = FALSE)
          message(sprintf("%s: got %6d runs starting at %15.0f\r", 
                          batchMsg, nrow(r), runID))
          runID <- max(r$runID)
        }
        
        ## ----------------------------------------------------------------------------
        ## 3. get hits for one new batch
        ## Start after the largest hitID we already have.
        ## (also get the count of hits we already have for this batch, to which we'll add
        ## new hits as we get them, writing the final total to the numHits field in
        ## this batch's record).
        ## ----------------------------------------------------------------------------
        
        # Hits for Batch ------------------------------------------------------
        hitID <- sql(paste0("select maxHitID from projBatch ",
                            "where tagDepProjectID = %d and batchID = %d"), 
                     projectID, batchID)[[1]]
        if (length(hitID) == 0) {
          hitID <- 0
          sql(paste0("insert into projBatch (tagDepProjectID, batchID, maxHitID) ",
                     "values (%d, %d, 0)"), projectID, batchID)
        }
        
        numHits <- 0
        repeat {
          h <- srvHitsForTagProject(projectID = projectID, batchID = batchID, 
                                    hitID = hitID)
          
          if (!isTRUE(nrow(h) > 0)) break
          message(sprintf("%s: got %6d hits starting at %15.0f\r", 
                          batchMsg, nrow(h), hitID))
          
          ## add these hit records to the DB
          DBI::dbWriteTable(sql$con, "hits", h, append = TRUE, row.names = FALSE)
          numHits <- numHits + nrow(h)
          hitID <- max(h$hitID)
          sql(paste0("update projBatch set maxHitID = %f ",
                     "where tagDepProjectID = %d and batchID = %d"), 
              hitID, projectID, batchID)
        }
        
        ## ----------------------------------------------------------------------------
        ## 4. get GPS fixes for this batch
        ## Start after the largest TS for which we already have a fix
        ## ----------------------------------------------------------------------------
        
        # GPS for Batch --------------------------------------------------------
        gpsID <- sql(paste0("SELECT ifnull(max(gpsID), 0) ",
                            "FROM gps WHERE batchID = %d"), batchID)[[1]]
        repeat {
          g <- srvGPSforTagProject(projectID = projectID, batchID = batchID, 
                                   gpsID = gpsID)
          if (!isTRUE(nrow(g) > 0)) break
          message(sprintf("%s: got %6d GPS fixes                     \r", 
                          batchMsg, nrow(g)))
          dbInsertOrReplace(sql$con, "gps", g)
          gpsID <- max(g$gpsID)
        }
        
        ## ----------------------------------------------------------------------------
        ## 5. write the record for this batch
        ## This marks the transfers for this batch as complete.
        ## ----------------------------------------------------------------------------
        # Save ----------------------------------------------------------------
        ## update the number of hits; this won't necessarily be
        ## the same value as supplied by the server, since our
        ## copy of this batch has only the hits from tags in this
        ## project, whereas the server's has hits from all
        ## projects's tags.
        
        if (nrow(oldBatch) == 0) {
          ## this is a new batch record, so write the whole thing
          b$numHits[bi] <- numHits
          ## dbWriteTable(sql$con, "batches", b[bi,], append = TRUE, row.names = FALSE)
          dbInsertOrReplace(sql$con, "batches", b[bi,], replace = FALSE)
        } else {
          ## this is a batch record we already have, but we've fetched
          ## additional hits due to ambiguous tags
          sql("update batches set numHits = numHits + %f where batchID = %d", 
              numHits, batchID)
        }
        
        # If testing, break out after x batches
        if(bi >= getOption("motus.test.max") && is_testing()) break
      }
      batchID <- max(b$batchID)
    }
  }
  motusUpdateDBmetadata(sql, tagIDs, devIDs, force = forceMeta)
  rv <- src
  rv
}
