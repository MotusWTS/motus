


pageDataByBatch <- function(src, table, resume = FALSE,
                            getBatches = NULL,
                            pageInitial, pageForward) {

  # Check tables and update to include table if necessary
  ensureDBTables(src, projRecv = get_projRecv(src))
  
  # Fetch/resume table download
  batches <- getBatches(src)
  
  # Check where to start
  if(resume) {
    # If updating, start with last batch downloaded (a bit of overlap)
    last_batch <- DBI_Query(src, "SELECT IFNULL(max(batchID), 0) from {`table`}")
    batches <- batches[batches >= last_batch]
  } else {
    # Otherwise remove all rows and start again
    DBI_Execute(src, "DELETE FROM {`table`}")
  }
  
  # If length zero, then no batches to get data for
  if(length(batches) > 0) {
    data_name <- get_projRecv(src)
    
    if(is_proj(data_name)) {
      projectID <- data_name
    } else {
      projectID <- NULL
    }

    # Get first batch
    b <- pageInitial(batches[1], projectID)
    
    # Check if actually new, or just the end of the record
    if(nrow(b) > 0 && resume && identical(last_batch, batches[length(batches)])) {
      bt <- batches[1]
      t <- dplyr::tbl(src, table) %>%
        dplyr::filter(.data$batchID == .env$bt) %>%
        dplyr::collect() %>%
        as.data.frame()
      if(identical(t, b)) {
        batches <- numeric()
        b <- data.frame()
      }
    }
  }  

  # Announce
  message(msg_fmt("{table}: {length(batches):5d} ",
                  dplyr::if_else(resume, "new ", ""),
                  "batch records to check"))
  
  added <- 0
  if(length(batches) > 0) {
    for(i in 1:length(batches)) {
      batchID <- batches[i]
      if(i != 1) b <- pageInitial(batchID, projectID)

      # Progress messages
      msg <- msg_fmt("batchID {batchID:8d} (#{i:6d} of {length(batches):6d}): ")
      
      # Progress messages when none
      if(nrow(b) == 0) { 
        message(msg, msg_fmt("got {0:6d} {table} records"))
      }
      
      # Get the rest of the data
      while(nrow(b) > 0) {
        # Save Previous batch
        dbInsertOrReplace(src, table, b)
        message(msg, msg_fmt("got {nrow(b):6d} {table} records"))
        added <- added + nrow(b)
        b <- pageForward(b, batchID, projectID)
      }

      # If testing, break out after x batches
      if(i >= getOption("motus.test.max") && is_testing()) break
    }
    message("Downloaded ", added, " ", table, " records")
  }
  src
}