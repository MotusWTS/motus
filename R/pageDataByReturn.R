
pageDataByReturn <- function(src, table, resume = FALSE, returnIDtype = "batchID",
                             pageInitial, pageForward) {

  check_src(src)
  
  # Check tables and update to include table if necessary
  ensureDBTables(src, projRecv = get_projRecv(src))

  returnID <- 0
  # Check where to start
  if(resume) {
    msg <- msg_fmt("{table}: checking for new data")
    # If updating, start with last batch downloaded (a bit of overlap)
    returnID <- DBI_Query(src, "SELECT IFNULL(max({returnIDtype}), 0) FROM {`table`}")  
  } else {
    msg <- msg_fmt("{table}: downloading all data")
    # Otherwise remove all rows and start again
    DBI_Execute(src,"DELETE FROM {table}")
  }
  
  # If length zero, then no batches to get data for
  data_name <- get_projRecv(src)
  
  if(is_proj(data_name)) {
    projectID <- data_name
  } else {
    projectID <- NULL
  }

  # Announce
  message(msg)
  
  # Get batch
  b <- pageInitial(returnID, projectID)
  
  added <- nrow(b)
  rounds <- 1
  
  # Progress messages
  message(msg_fmt("{returnIDtype} {returnID:8d}: got {nrow(b):6d} {table} records"))

  repeat {
    
    # Save Previous batch
    dbInsertOrReplace(src, table, b)
    added <- added + nrow(b)

    # Page forward
    returnID <- b[[returnIDtype]][nrow(b)]
    b <- pageForward(b, returnID, projectID)
    
    # Progress messages
    message(msg_fmt("{returnIDtype} {returnID:8d}: got {nrow(b):6d} {table} records"))
    
    if(nrow(b) == 0) break
    
    # If testing, break out after x batches
    rounds <- rounds + 1
    if(rounds >= getOption("motus.test.max") && is_testing()) break
  }
  
  message(msg_fmt("Downloaded {added} {table} {records}"))
  
  src
}
  