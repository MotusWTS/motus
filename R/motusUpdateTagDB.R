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
  
  # keep track of items we'll need metadata for
  tagIDs <- c()
  devIDs <- c()
  
  for (projectID in projectIDs) {
    batchID <- sql(paste0("select ifnull(max(a.batchID), 0) from projBatch a ",
                          "inner join batches b on a.batchID = b.batchID ",
                          "where tagDepProjectID = %d"), projectID)[[1]]
    
    # 1. Get records for all new Batches ---------------------------------------
    # Start after the latest batch we already have.
    
    repeat {
      # we always use countOnly = FALSE, because we need to obtain batchIDs
      # in order to count runs and hits
      b <- srvBatchesForTagProject(projectID = projectID, batchID = batchID)
      if (!isTRUE(nrow(b) > 0)) break

      # Check that version matches (just in case)
      if(any(b$version != dplyr::tbl(src$con, "admInfo") %>%
             dplyr::pull(.data$data_version))) {
        stop("Server data version doesn't match the version in this database",
             call. = FALSE)
      }
      
      # temporary work-around to batches with incorrect starting timestamps
      # (e.g. negative, or on CLOCK_MONOTONIC) that make a batch appears
      # to span multiple deployments.
      b <- subset(b, !duplicated(batchID))

      devIDs <- unique(c(devIDs, b$motusDeviceID))
      message(sprintf("Project %5d:  got %5d batch records", projectID, nrow(b)))
      
      for (bi in 1:nrow(b)) {
        batchID <- b$batchID[bi]
        # grab existing batch record, if any.  This will only return
        # a non-empty result if we're currently grabbing data for a
        # project with which the main project has an ambiguous tag.
        oldBatch <- sql("select * from batches where batchID = %d", batchID)
        batchMsg <- sprintf("batchID %8d (#%6d of %6d)", batchID, bi, nrow(b))
        
        # To handle interruption of transfers, we save a record to the batches
        # table as the last step after acquiring runs and hits for that batch.
        
        # 2. Runs for one new batch -------------------------------------------
        tagIDs <- unique(c(tagIDs, runsForBatch(sql, batchID, batchMsg, projectID)))
        
        # 3. Hits for one new batch -------------------------------------------
        numHits <- hitsForBatchProject(sql, batchID, batchMsg, projectID)
        
        # 4. GPS for for this Batch -------------------------------------------
        gpsForBatchProject(sql, batchID, batchMsg, projectID)
        
        # 5. Save - write the record for this batch ---------------------------
        # This marks the transfers for this batch as complete.
        # update the number of hits; this won't necessarily be
        # the same value as supplied by the server, since our
        # copy of this batch has only the hits from tags in this
        # project, whereas the server's has hits from all
        # projects's tags.
        
        if(nrow(oldBatch) == 0) {
          # this is a new batch record, so write the whole thing
          b$numHits[bi] <- numHits
          # dbWriteTable(sql$con, "batches", b[bi,], append = TRUE, row.names = FALSE)
          dbInsertOrReplace(sql$con, "batches", b[bi,], replace = FALSE)
        } else {
          # this is a batch record we already have, but we've fetched
          # additional hits due to ambiguous tags
          sql("update batches set numHits = numHits + %f where batchID = %d", 
              numHits, batchID)
        }
        # If testing, break out after x batches
        if(bi >= getOption("motus.test.max") && is_testing()) break
      }
      if(bi >= getOption("motus.test.max") && is_testing()) break
      batchID <- max(b$batchID)
    }
  }
  
  message("Updating metadata")
  motusUpdateDBmetadata(sql, tagIDs, devIDs, force = forceMeta)
  rv <- src
  rv
}
