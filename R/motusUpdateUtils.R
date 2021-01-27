#' Get runs by batch for Tags
#' 
#' Start with runID <- 0, because we don't know in advance what runs that we
#' already have records for might be modified by each batch
#'
#' @param sql 
#' @param projectID 
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd

runsForBatch <- function(sql, batchID, batchMsg, projectID = NULL) {
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
    dbInsertOrReplace(sql$con, "runs", r)
    DBI::dbWriteTable(sql$con, "batchRuns", 
                      data.frame(batchID = batchID, runID = r$runID), 
                      append = TRUE, row.names = FALSE)
    message(sprintf("%s: got %6d runs starting at %15.0f\r", 
                    batchMsg, nrow(r), runID))
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
#' @param sql 
#' @param batchID 
#' @param batchMsg 
#' @param projectID 
#'
#' @noRd
hitsForBatchProject <- function(sql, batchID, batchMsg, projectID = NULL) {
  
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
    h <- srvHitsForTagProject(projectID = projectID, 
                              batchID = batchID, 
                              hitID = hitID)
    
    if (!isTRUE(nrow(h) > 0)) break
    message(sprintf("%s: got %6d hits starting at %15.0f\r", 
                    batchMsg, nrow(h), hitID))
    
    # add these hit records to the DB
    # Because some extra fields will cause this to error, use dbInsertOrReplace
    dbInsertOrReplace(sql$con, "hits", h)
    hitID <- max(h$hitID)
    
    numHits <- numHits + nrow(h)
    
    sql(paste0("update projBatch set maxHitID = %f ",
               "where tagDepProjectID = %d and batchID = %d"), 
        hitID, projectID, batchID)
  }
  numHits
}

#' Get hits by batches for Receivers
#' 
#' Start after the largest hitID we already have.
#'
#' @param sql 
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd
hitsForBatchReceiver <- function(sql, batchID, batchMsg) {
  
  hitID <- sql("select ifnull(max(hitID), 0) from hits where batchID=%d",
               batchID)[[1]]
  
  repeat {
    h <- srvHitsForReceiver(batchID = batchID, hitID = hitID)
    
    
    if (!isTRUE(nrow(h) > 0)) break
    message(sprintf("%s: got %6d hits starting at %15.0f\r", 
                    batchMsg, nrow(h), hitID))
    
    # add these hit records to the DB
    # Because some extra fields will cause this to error, use dbInsertOrReplace
    dbInsertOrReplace(sql$con, "hits", h)
    hitID <- max(h$hitID)
  } 
}


#' Get GPS points by batch for Tags
#' 
#' Start after the largest gpsID for which we already have a fix
#'
#' @param sql 
#' @param batchID 
#' @param batchMsg 
#' @param projectID
#'
#' @noRd
gpsForBatchProject <- function(sql, batchID, batchMsg, projectID) {
  gpsID <- sql(paste0("SELECT ifnull(max(gpsID), 0) ",
                      "FROM gps WHERE batchID = %d"), batchID)[[1]]
  repeat {
    g <- srvGPSForTagProject(projectID = projectID, 
                             batchID = batchID, 
                             gpsID = gpsID)
    if (!isTRUE(nrow(g) > 0)) break
    message(sprintf("%s: got %6d GPS fixes                     \r", 
                    batchMsg, nrow(g)))
    dbInsertOrReplace(sql$con, "gps", g)
    gpsID <- max(g$gpsID)
  } 
}

#' Get GPS points by batch for Receivers
#' 
#' Start after the largest TS for which we already have a fix
#'
#' @param sql 
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd
gpsForBatchReceiver <- function(sql, batchID, batchMsg) {
  gpsID <- sql(paste0("SELECT ifnull(max(gpsID), 0) ",
                      "FROM gps WHERE batchID = %d"), batchID)[[1]]
  repeat {
    g <- srvGPSForReceiver(batchID = batchID, gpsID = gpsID)
    if (!isTRUE(nrow(g) > 0)) break
    message(sprintf("%s: got %6d GPS fixes                     \r", 
                    batchMsg, nrow(g)))
    dbInsertOrReplace(sql$con, "gps", 
                      g[, c("batchID", "ts", "gpsts", "lat", "lon", "alt")])
    gpsID <- max(g$gpsID)
  } 
}

#' Get pulse counts by batch for Receivers
#'
#' Start after the largest ant, hourBin for which we already have pulseCounts
#' from this batch.
#' @param sql 
#' @param batchID 
#' @param batchMsg 
#'
#' @noRd
pulseForBatchReceiver <- function(sql, batchID, batchMsg) {
  info <- sql("select ant, hourBin from pulseCounts where batchID=%d order by ant desc, hourBin desc limit 1", batchID)
  if (nrow(info) == 1) {
    ant <- info[[1]]
    hourBin <- info[[2]]
  } else {
    ant <- 0
    hourBin <- 0
  }
  
  repeat {
    pc <- srvPulseCountsforReceiver(batchID = batchID, ant = ant, hourBin = hourBin)
    if (!isTRUE(nrow(pc) > 0)) break
    message(sprintf("%s: got %6d pulse counts                     \r", 
                    batchMsg, nrow(pc)))
    dbInsertOrReplace(sql$con, "pulseCounts", 
                      pc[, c("batchID", "ant", "hourBin", "count")])
    ant <- utils::tail(pc$ant, 1)
    hourBin <- utils::tail(pc$hourBin, 1)
  }
}
