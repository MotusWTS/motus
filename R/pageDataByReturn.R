
pageDataByReturn <- function(src, table, resume = FALSE, returnIDtype = "batchID",
                             pageInitial, pageForward) {

  # Check tables and update to include table if necessary
  ensureDBTables(src, projRecv = get_projRecv(src))
  sql <- safeSQL(src)
  
  returnID <- 0
  # Check where to start
  if(resume) {
    msg <- sprintf("%s: checking for new data", table)
    # If updating, start with last batch downloaded (a bit of overlap)
    returnID <- sql(glue::glue("select ifnull(max({returnIDtype}), 0) from ", table))[[1]]  
  } else {
    msg <- sprintf("%s: downloading all data", table)
    # Otherwise remove all rows and start again
    DBI::dbExecute(src$con, paste0("DELETE FROM ", table))
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
  message(sprintf("%s %8d: ", returnIDtype, returnID), sprintf("got %6d %s records", nrow(b), table))

  repeat {
    
    # Save Previous batch
    dbInsertOrReplace(sql$con, table, b)
    added <- added + nrow(b)

    # Page forward
    returnID <- b[[returnIDtype]][nrow(b)]
    b <- pageForward(b, returnID, projectID)
    
    # Progress messages
    message(sprintf("%s %8d: ", returnIDtype, returnID), sprintf("got %6d %s records", nrow(b), table))
    
    if(nrow(b) == 0) break
    
    # If testing, break out after x batches
    rounds <- rounds + 1
    if(rounds >= getOption("motus.test.max") && is_testing()) break
  }
  
  message("Downloaded ", added, " ", table, " records")
  
  src
}
  