#' Add/update batch activity
#' 
#' Download or resume a download of the 'activity' table in an existing Motus
#' database. Batch activity refers to the number of hits detected during a given
#' batch. Batches with large numbers of hits may indicate interference and thus
#' unreliable hits.
#'
#' @param src src_sqlite object representing the database
#' @param resume Logical. Resume a download? Otherwise the activity table is
#'   removed and the download is started from the beginning.
#' 
#' @details This function is automatically run by the [tagme()] function with
#'   `resume = TRUE`. 
#'   
#'   If an 'activity' table doesn't exist, it will be created prior to
#'   downloading. If there is an existing 'activity' table, this will update the
#'   records.
#'
#' @examples
#' 
#' # download and access data from project 176 in sql format
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#'   
#' # Access 'activity' table
#' library(dplyr)
#' a <- tbl(sql.motus, "activity")
#'   
#' # If interrupted and you want to resume
#' \dontrun{my_tags <- activity(sql.motus, resume = TRUE)}
#'
#' @export

activity <- function(src, resume = FALSE) {
  # Update to include activity table
  src <- updateMotusDb(src, src)
  
  sql <- safeSQL(src)
  
  # Fetch/resume activity download
  batches <- sql("select batchID from batches")[[1]]
  p <- sql("select val from meta where key='tagProject'")[[1]] %>%
    as.integer()

  if(resume) {
    # If updating, start with last batch downloaded (a bit of overlap)
    last_batch <- sql("select ifnull(max(batchID), 0) from activity")[[1]]  
    batches <- batches[batches >= last_batch]
  } else {
    # Otherwise remove all rows and start again
    DBI::dbExecute(src$con, "DELETE FROM activity")
  }
  
  if(length(batches) > 0) {
    for(i in 1:length(batches)) {
      batchID <- batches[i]
      # Get first batch
      b <- srvActivityForBatches(batchID = batchID)
      
      # If this is the last batch, check if actually new, or just the end of the record
      if(resume && i == 1 && identical(last_batch, batches)) {
        t <- dplyr::tbl(src$con, "activity") %>%
          dplyr::filter(batchID == batches[i]) %>%
          dplyr::collect() %>%
          as.data.frame()
        if(identical(t, b)) break 
      }
      
      # Only first time
      if(i == 1) message(sprintf("Project %5d:  %5d batch records to check", 
                                 p, length(batches)))
      
      # Progress messages
      msg <- sprintf("batchID %8d (#%6d of %6d): ", batchID, i, length(batches))
      
      # Get the rest of the data
      while(nrow(b) > 0) {
        # Save Previous batch
        dbInsertOrReplace(sql$con, "activity", b)
        message(msg, sprintf("got %6d activity records", nrow(b)))
        
        # Page forward
        ant <- b$ant[nrow(b)]
        hourBin <- b$hourBin[nrow(b)]
        
        # Try again
        b <- srvActivityForBatches(batchID = batchID, 
                                   ant = ant, hourBin = hourBin)
      }
    }
  }
  src
}