#' Add/update all activity
#' 
#' Download or resume a download of all `activity`. Batch activity refers to the
#' number of hits detected during a given batch. Batches with large numbers of
#' hits may indicate interference and thus unreliable hits.
#'
#' @param src src_sqlite object representing the database
#' @param resume Logical. Resume a download? Otherwise the `activity` table is
#'   removed and the download is started from the beginning.
#'   
#'   If an `activity` table doesn't exist, it will be created prior to
#'   downloading. If there is an existing `activity` table, this will update the
#'   records.
#'
#' @examples
#' 
#'
#' @export

activityAll <- function(src, resume = FALSE) {
  
  getBatches <- function(src) {
    b <- dplyr::tbl(src$con, "activity") %>%
      dplyr::pull(.data$batchID)
    if(length(b) == 0) b <- 0
    b
  }
  
  pageInitial <- function(batchID, projectID) srvActivityForAll(batchID = batchID)
  
  pageForward <- function(b, batchID) {
    # Page forward
    ant <- b$ant[nrow(b)]
    hourBin <- b$hourBin[nrow(b)]
    
    # Try again
    srvActivityForBatches(batchID = batchID, 
                          ant = ant, hourBin = hourBin) 
  }
  
  pageDataByBatch(src, table = "activity", resume = resume,
                  getBatches, pageInitial, pageForward)
  
}