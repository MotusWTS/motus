#' Update project database
#'
#' @param src SQLite Connection
#' @param countOnly Logical. Count results instead of returning them?
#' @param forceMeta Logical. If true, re-get metadata for tags and receivers,
#'   even if we already have them.  Default:  `FALSE.`
#'
#' @return `src`, if `countOnly` is `FALSE.`  Otherwise, a list of counts items
#'   that would be transferred by the update.
#'
#' @seealso `tagme()`, which is intended for most users, and indirectly calls
#'   this function.
#'
#' @noRd

motusUpdateTagDB <- function(src, countOnly = FALSE, forceMeta = FALSE) {

  projectID <- get_projRecv(src)
  batchID <- max_batch(src, projectID)

  if(countOnly) {
    DBI::dbDisconnect(src)
    return(srvSizeOfUpdateForTagProject(projectID = projectID, 
                                        batchID = batchID))
  }

  ambigProjs <- srvProjectAmbiguitiesForTagProject(projectID)
  dbInsertOrReplace(src, "projAmbig", ambigProjs)
  projectIDs <- unique(c(projectID, ambigProjs$ambigProjectID))
  
  msg <- msg_fmt("Checking for new data in project {projectID}")
  if (length(projectIDs) > 1) {
    msg <- msg_fmt(msg, "\nand in ambiguous detection projects ", 
                   glue::glue_collapse(projectIDs[-1], sep = ", "))
  }
  message(msg)
  
  # keep track of items we'll need metadata for
  tagIDs <- c()
  devIDs <- c()
  
  for (projectID in projectIDs) {
    batchID <- max_batch(src, projectID)
    
    # 1. Get records for all new Batches ---------------------------------------
    # Start after the latest batch we already have.
    
    repeat {
      # we always use countOnly = FALSE, because we need to obtain batchIDs
      # in order to count runs and hits
      b <- srvBatchesForTagProject(projectID = projectID, batchID = batchID)
      if (!isTRUE(nrow(b) > 0)) break

	  lastBatchID = max(b$batchID, na.rm = TRUE)

      # get next set of blu batches within the batchID range of b
      b2 <- srvHitsBluBatchesForTagProject(projectID = projectID, batchID = batchID, lastBatchID = lastBatchID)

      # Check that version matches (just in case)
      if(any(b$version != dplyr::tbl(src, "admInfo") %>%
             dplyr::pull(.data$data_version))) {
        stop("Server data version doesn't match the version in this database",
             call. = FALSE)
      }
      
      # temporary work-around to batches with incorrect starting timestamps
      # (e.g. negative, or on CLOCK_MONOTONIC) that make a batch appears
      # to span multiple deployments.
      b <- subset(b, !duplicated(batchID))

      devIDs <- unique(c(devIDs, b$motusDeviceID))
      message(msg_fmt("Project {projectID:5d}:  got {nrow(b):5d} batch records"))
      
      for (bi in 1:nrow(b)) {
        batchID <- b$batchID[bi]
        # grab existing batch record, if any.  This will only return
        # a non-empty result if we're currently grabbing data for a
        # project with which the main project has an ambiguous tag.
        oldBatch <- DBI_Query(src, "select * from batches where batchID = {batchID}")
        
        batchMsg <- msg_fmt("batchID {batchID:8d} (#{bi:6d} of {nrow(b):6d})")
        
        # To handle interruption of transfers, we save a record to the batches
        # table as the last step after acquiring runs and hits for that batch.
        
        # 2. Runs for one new batch -------------------------------------------
        tagIDs <- unique(c(tagIDs, runsForBatch(src, batchID, batchMsg, projectID)))
        
        # 3. Hits for one new batch -------------------------------------------
        numHits <- hitsForBatchProject(src, batchID, batchMsg, projectID)

        # 3b. Hits blue for one new batch (if necessary)-----------------------
        if (batchID %in% b2$batchID) {
          hitsBluForBatchProject(src, batchID, batchMsg, projectID)
        }

        # 4. GPS for for this Batch -------------------------------------------
        gpsForBatchProject(src, batchID, batchMsg, projectID)
        
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
          dbInsertOrReplace(src, "batches", b[bi,], replace = FALSE)
        } else {
          # this is a batch record we already have, but we've fetched
          # additional hits due to ambiguous tags
          DBI_Execute(src,
                      "UPDATE batches SET numHits = numHits + {numHits} ",
                      "WHERE batchID = {batchID}")
        }
        # If testing, break out after x batches
        if(bi >= getOption("motus.test.max") && is_testing()) break
      }
      if(bi >= getOption("motus.test.max") && is_testing()) break
      batchID <- max(b$batchID)
    }
  }
  
  message("Updating metadata")
  motusUpdateDBmetadata(src, tagIDs, devIDs, force = forceMeta)
  
  src
}

max_batch <- function(src, projectID) {
  DBI_Query(src,
            "SELECT IFNULL(max(a.batchID), 0) FROM projBatch a ",
            "INNER JOIN batches b ON a.batchID = b.batchID ",
            "WHERE tagDepProjectID = {projectID}")
}
