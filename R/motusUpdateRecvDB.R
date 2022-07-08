#' Update a motus tag detection database - receiver flavour (backend)
#'
#' @param src SQLite connection (result of `tagme(XXX)` or
#'   `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`)
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

motusUpdateRecvDB <- function(src, countOnly, forceMeta = FALSE) {
  check_src(src)
  
  recvSerno <- DBI_Query(src, "SELECT val FROM meta WHERE key = 'recvSerno'")
  deviceID <- DBI_Query(src, "SELECT val FROM meta WHERE key = 'deviceID'") %>%
    as.integer()
  
  if (!isTRUE(deviceID > 0)) {
    stop("This receiver database does not have a valid deviceID stored in it.\n",
         "Try delete or rename the file and use tagme() again?", call. = FALSE)
  }
  
  batchID <- DBI_Query(src, "SELECT IFNULL(max(batchID), 0) FROM batches")
  
  if (countOnly) {
    DBI::dbDisconnect(src)
    return(srvSizeOfUpdateForReceiver(deviceID = deviceID, batchID = batchID))
  }
  
  # keep track of items we'll need metadata for
  tagIDs <- c()
  
  # 1. get records for all new batches -----------------------------------------
  # Start after the latest batch we already have.
  message(msg_fmt("Checking for new data for receiver {recvSerno} ", 
                  "(deviceID: {deviceID})"))
  
  repeat {
    # we always use countOnly = FALSE, because we need to obtain batchIDs
    # in order to count runs and hits
    b <- srvBatchesForReceiver(deviceID = deviceID, batchID = batchID)
    if (! isTRUE(nrow(b) > 0)) break
    # temporary work-around to batches with incorrect starting timestamps
    # (e.g. negative, or on CLOCK_MONOTONIC) that make a batch appears
    # to span multiple deployments.
    b <- subset(b, !duplicated(batchID))
    
    message(msg_fmt("Receiver {recvSerno}:  got {nrow(b):5d} batch records"))
    for (bi in 1:nrow(b)) {
      batchID <- b$batchID[bi]
        
      batchMsg <- msg_fmt("batchID {batchID:8d} (#{bi:6d} of {nrow(b):6d})")
      # To handle interruption of transfers, we save a record to the batches
      # table as the last step after acquiring runs and hits for that batch.
      
      # 2. Runs for one new batch ----------------------------------------------
      tagIDs <- runsForBatch(src, batchID, batchMsg)
      
      # 3. Hits for one new batch ----------------------------------------------
      hitsForBatchReceiver(src, batchID, batchMsg)
      
      # 4. GPS for for this Batch ----------------------------------------------
      gpsForBatchReceiver(src, batchID, batchMsg)
      
      # 5. get pulse counts for this batch -------------------------------------
      pulseForBatchReceiver(src, batchID, batchMsg)
      
      # 6. Save - write the record for this batch ------------------------------
      # This marks the transfers for this batch as complete.
      dbInsertOrReplace(src, "batches", b[bi,], replace=FALSE)
      
      # If testing, break out after x batches
      if(bi >= getOption("motus.test.max") && is_testing()) break
    }
    batchID <- max(b$batchID)
  }
  
  motusUpdateDBmetadata(src, tagIDs, deviceID, force = forceMeta)
  
  src
}
