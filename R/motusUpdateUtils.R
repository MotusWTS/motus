#' Get runs by batch for Tags
#' 
#' Start with runID <- 0, because we don't know in advance what runs that we
#' already have records for might be modified by each batch
#'
#' @param src 
#' @param projectID 
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd

runsForBatch <- function(src, batchID, batchMsg, projectID = NULL) {
  runID <- 0
  tagIDs <- vector()
  repeat {
    if(is.null(projectID)){
      r <- srvRunsForReceiver(batchID = batchID, runID = runID)
    } else {
      r <- srvRunsForTagProject(projectID = projectID, batchID = batchID, 
                                runID = runID)
    }
    
    if (!isTRUE(nrow(r) > 0)) break
    
    tagIDs <- c(tagIDs, r$motusTagID)
    
    ## add these run records to the DB
    ## Because some might be updates, or a previous transfer might have been
    ## interrupted, use dbInsertOrReplace
    
    dbInsertOrReplace(src, "runs", r)
    DBI::dbWriteTable(src, "batchRuns", 
                      data.frame(batchID = batchID, runID = r$runID), 
                      append = TRUE, row.names = FALSE)
    message(msg_fmt("{batchMsg}: got {nrow(r):6d} runs starting at {runID:15.0f}"))
    runID <- max(r$runID)
  }
  tagIDs
}

#' Get hits by batches for Tags
#' 
#' Start after the largest hitID we already have.
#' Also get the count of hits we already have for this batch, to which we'll add
#' new hits as we get them, writing the final total to the numHits field in this
#' batch's record).
#'
#' @param src 
#' @param batchID 
#' @param batchMsg 
#' @param projectID 
#'
#' @noRd
hitsForBatchProject <- function(src, batchID, batchMsg, projectID = NULL) {

  hitID <- DBI_Query(src,
                     "SELECT maxHitID FROM projBatch ",
                     "WHERE tagDepProjectID = {projectID} ",
                     "AND batchID = {batchID}")
  
  if (length(hitID) == 0) {
    hitID <- 0
    DBI_Execute(src, 
                "INSERT INTO projBatch (tagDepProjectID, batchID, maxHitID) ",
                "VALUES ({projectID}, {batchID}, 0)")
  }
  
  numHits <- 0
  
  repeat {
    h <- srvHitsForTagProject(projectID = projectID, 
                              batchID = batchID, 
                              hitID = hitID)
    
    if (!isTRUE(nrow(h) > 0)) break
    message(msg_fmt("{batchMsg}: got {nrow(h):6d} hits starting at {hitID:15.0f}"))
    
    # add these hit records to the DB
    # Because some extra fields will cause this to error, use dbInsertOrReplace
    dbInsertOrReplace(src, "hits", h)
    hitID <- max(h$hitID)
    
    numHits <- numHits + nrow(h)
    
    DBI_Execute(src, 
                "UPDATE projBatch SET maxHitID = {hitID} ",
                "WHERE tagDepProjectID = {projectID} AND batchID = {batchID}")
  }
  numHits
}

#' Get hits by batches for Receivers
#' 
#' Start after the largest hitID we already have.
#'
#' @param src
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd
hitsForBatchReceiver <- function(src, batchID, batchMsg) {
  
  hitID <- DBI_Query(src, 
                     "SELECT IFNULL(max(hitID), 0) FROM hits WHERE batchID = {batchID}")
  
  repeat {
    h <- srvHitsForReceiver(batchID = batchID, hitID = hitID)
    
    
    if (!isTRUE(nrow(h) > 0)) break
    message(msg_fmt("{batchMsg}: got {nrow(h):6d} hits starting at {hitID}"))
    
    # add these hit records to the DB
    # Because some extra fields will cause this to error, use dbInsertOrReplace
    dbInsertOrReplace(src, "hits", h)
    hitID <- max(h$hitID)
  } 
}


#' Get GPS points by batch for Tags
#' 
#' Start after the largest gpsID for which we already have a fix
#'
#' @param src 
#' @param batchID 
#' @param batchMsg 
#' @param projectID
#'
#' @noRd
gpsForBatchProject <- function(src, batchID, batchMsg, projectID) {
  gpsID <- DBI_Query(src, 
                     "SELECT ifnull(max(gpsID), 0) ",
                     "FROM gps WHERE batchID = {batchID}")
  repeat {
    g <- srvGPSForTagProject(projectID = projectID, 
                             batchID = batchID, 
                             gpsID = gpsID)
    if (!isTRUE(nrow(g) > 0)) break
    message(msg_fmt("{batchMsg}: got {nrow(g):6d} GPS fixes"))
    dbInsertOrReplace(src, "gps", g)
    gpsID <- max(g$gpsID)
  } 
}

#' Get GPS points by batch for Receivers
#' 
#' Start after the largest TS for which we already have a fix
#'
#' @param src
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd
gpsForBatchReceiver <- function(src, batchID, batchMsg) {
  gpsID <- DBI_Query(src, 
                     "SELECT ifnull(max(gpsID), 0) ",
                     "FROM gps WHERE batchID = {batchID}")
  repeat {
    g <- srvGPSForReceiver(batchID = batchID, gpsID = gpsID)
    if (!isTRUE(nrow(g) > 0)) break
    message(msg_fmt("{batchMsg}: got {nrow(g):6d} GPS fixes"))
    dbInsertOrReplace(src, "gps", 
                      g[, c("batchID", "ts", "gpsts", "lat", "lon", "alt")])
    gpsID <- max(g$gpsID)
  } 
}

#' Get pulse counts by batch for Receivers
#'
#' Start after the largest ant, hourBin for which we already have pulseCounts
#' from this batch.
#' @param src 
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd
pulseForBatchReceiver <- function(src, batchID, batchMsg) {
  info <- DBI_Query(
    src, 
    "SELECT ant, hourBin FROM pulseCounts WHERE batchID = {batchID}",
    "ORDER BY ant DESC, hourBin DESC LIMIT 1")
  if (nrow(info) == 1) {
    ant <- info[[1]]
    hourBin <- info[[2]]
  } else {
    ant <- 0
    hourBin <- 0
  }
  
  repeat {
    pc <- srvPulseCountsForReceiver(batchID = batchID, ant = ant, hourBin = hourBin)
    if (!isTRUE(nrow(pc) > 0)) break
    message(msg_fmt("{batchMsg}: got {nrow(pc):6d} pulse counts"))
    dbInsertOrReplace(src, "pulseCounts", 
                      pc[, c("batchID", "ant", "hourBin", "count")])
    ant <- utils::tail(pc$ant, 1)
    hourBin <- utils::tail(pc$hourBin, 1)
  }
}
