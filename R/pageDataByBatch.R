


pageDataByBatch <- function(src, table, resume = FALSE,
                            getBatches = NULL,
                            pageInitial, pageForward) {

  # Check tables and update to include table if necessary
  ensureDBTables(src, projRecv = get_projRecv(src))
  sql <- safeSQL(src)
  
  # Fetch/resume table download
  batches <- getBatches(src)
  
  # Check where to start
  if(resume) {
    # If updating, start with last batch downloaded (a bit of overlap)
    last_batch <- sql(paste0("select ifnull(max(batchID), 0) from ", table))[[1]]  
    batches <- batches[batches >= last_batch]
  } else {
    # Otherwise remove all rows and start again
    DBI_Execute(src, "DELETE FROM {table}")
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
      t <- dplyr::tbl(src, table) %>%
        dplyr::filter(.data$batchID == batches[1]) %>%
        dplyr::collect() %>%
        as.data.frame()
      if(identical(t, b)) {
        batches <- numeric()
        b <- data.frame()
      }
    }
  }  

  # Announce
  message(msg_fmt(
    "{table}: {length(batches):5d} {dplyr::if_else(resume, 'new', '')}",
    "batch records to check"))
  
  added <- 0
  if(length(batches) > 0) {
    for(i in 1:length(batches)) {
      batchID <- batches[i]
      if(i != 1) b <- pageInitial(batchID, projectID)

      # Get the rest of the data
      while(nrow(b) > 0) {
        
        # Progress messages
        msg <- msg_fmt("batchID {batchID:8d} (#{i:6d} of {length(batches):6d}): ")
        
        # Save Previous batch
        dbInsertOrReplace(sql, table, b)
        message(msg, msg_fmt("got {nrow(b):6d} {table} records"))
        added <- added + nrow(b)
        b <- pageForward(b, batchID, projectID)
      }
      
      # Progress messages
      if(nrow(b) == 0) { 
        message(msg_fmt(
          "batchID {batchID:8d} (#{i:6d} of {length(batches):6d}: ",
          "got       0 {table} records"))
      }
      
      # If testing, break out after x batches
      if(i >= getOption("motus.test.max") && is_testing()) break
    }
    message("Downloaded ", added, " ", table, " records")
  }
  src
}