#' Add/update batch activity
#' 
#' Download or resume a download of the `activity` table in an existing Motus
#' database. Batch activity refers to the number of hits detected during a given
#' batch. Batches with large numbers of hits may indicate interference and thus
#' unreliable hits.
#'
#' @inheritParams args
#' 
#' @details This function is automatically run by the [tagme()] function with
#'   `resume = TRUE`. 
#'   
#'   If an `activity` table doesn't exist, it will be created prior to
#'   downloading. If there is an existing `activity` table, this will update the
#'   records.
#'
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#'    
#' # Access 'activity' table
#' library(dplyr)
#' a <- tbl(sql_motus, "activity")
#'   
#' # If interrupted and you want to resume
#' \dontrun{my_tags <- activity(sql_motus, resume = TRUE)}
#'
#' @export

activity <- function(src, resume = FALSE) {
  
  getBatches <- function(src) {
    dplyr::tbl(src, "batches") %>%
      dplyr::pull(.data$batchID)
  }
  
  pageInitial <- function(batchID, projectID) srvActivityForBatches(batchID = batchID)
  
  pageForward <- function(b, batchID, projectID) {
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