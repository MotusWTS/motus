#' Fetch and remove deprecated batches
#' 
#' Deprecated batches are removed from the online database but not from 
#' local data files. This function fetches a list of deprecated batches
#' (stored in the 'deprecated' table), and, optionally, removes these batches 
#' from all tables that reference `batchID`s
#'
#' @param fetchOnly Logical. Only *fetch* batches that are deprecated. Don't 
#'   remove deprecated batches from other tables.
#' @param ask Logical. Ask for confirmation when removing deprecated batches
#' 
#' @inheritParams args
#'
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{
#' sql_motus <- tagme(176, new = TRUE)
#'   
#' # Access 'deprecated' table using tbl() from dplyr
#' library(dplyr)
#' tbl(sql_motus, "deprecated")
#' 
#' # See that there are deprecated batches in the data
#' filter(tbl(sql_motus, "alltags"), batchID == 6000)
#' 
#' # Fetch deprecated batches
#' deprecateBatches(sql_motus, fetchOnly = TRUE)
#' 
#' # Remove deprecated batches (will ask for confirmation unless ask = FALSE)
#' deprecateBatches(sql_motus, ask = FALSE)
#' 
#' # See that there are NO more deprecated batches in the data
#' filter(tbl(sql_motus, "alltags"), batchID == 6000)
#' }
#' 
#' @export

deprecateBatches <- function(src, fetchOnly = FALSE, ask = TRUE) {
  src <- fetchDeprecated(src)
  if(!fetchOnly) src <- removeDeprecated(src, ask)
  src
}

fetchDeprecated <- function(src, verbose = FALSE) {
  
  message("Fetching deprecated batches")
  
  # Tags or Receiver?
  projRecv <- get_projRecv(src)
  if(is_proj(projRecv)) dep <- srvBatchesForTagProjectDeprecated
  if(!is_proj(projRecv)) {
    dep <- srvBatchesForReceiverDeprecated
    projRecv <- srvDeviceIDForReceiver(projRecv)[[2]]
  }
  
  # Fetch complete deprecated batch record (always needs to get the complete)
  b1 <- dep(projRecv, 0, verbose) # First run
  b <- b1
  while(nrow(b1) == 10000) { # Page until have it all
    b1 <- dep(projRecv, dplyr::last(b1$batchID), verbose)
    b <- dplyr::bind_rows(b, b1)
  }

  # Only get new batches
  if(nrow(b) > 0) {
    new <- dplyr::tbl(src, "deprecated") %>% 
      dplyr::collect() %>%
      dplyr::anti_join(b, ., by = "batchID") %>%
      dplyr::mutate(removed = 0)
  } else new <- data.frame()

  # Add to deprecated table
  dbInsertOrReplace(src, "deprecated", new)
  message("Total deprecated batches: ", nrow(b), 
          "\nNew deprecated batches: ", nrow(new))
  
  src
}

removeDeprecated <- function(src, ask) {
  deprecated <- dplyr::tbl(src, "deprecated") %>%
    dplyr::filter(!.data$removed) %>%
    dplyr::mutate(removed = 1) %>%
    dplyr::collect()
  
  d <- dplyr::pull(deprecated, .data$batchID)
  
  if(length(d) == 0) {
    message("No new deprecated batches to remove")
    return(src)
  }
  
  if(ask) {
    continue <- utils::menu(
      choices = c("TRUE" = "Yes", "FALSE" = "No"), 
      title = glue::glue(
        "You are about to permanently delete up to {length(d)} deprecated ", 
        "batches from\n{src@dbname}\nContinue?")) == 1
    if(!continue) stop("Aborting, leaving deprecated batches as is", 
                       call. = FALSE)
  }
    
  # Remove deprecated batches from all tables
  removeByID(src, t = "runs", id_type = "batchIDbegin", ids = d)
  removeByID(src, t = "hits", ids = d)
  removeByID(src, t = "activity", ids = d)
  removeByID(src, t = "activityAll", ids = d)
  removeByID(src, t = "gps", ids = d)
  removeByID(src, t = "gpsAll", ids = d)
  removeByID(src, t = "batchRuns", ids = d)
  removeByID(src, t = "nodeData", ids = d)
  removeByID(src, t = "projBatch", ids = d)
  removeByID(src, t = "batches", ids = d)
  
  dbInsertOrReplace(src, "deprecated", deprecated)
  
  message("Repacking data base to save space...")
  DBI_Execute(src, "VACUUM")
  message("Total deprecated batches removed: ", length(d))
  
  src
}

removeByID <- function(src, t, id_type = "batchID", ids) {
  if(length(ids) > 0) {
    if(t %in% DBI::dbListTables(src)) {
      n <- DBI_Execute(src, 
                       "DELETE FROM {`t`} WHERE {`id_type`} IN (",
                       glue::glue_collapse(ids, sep = ', '), 
                       ")")
      if(n > 0) message(msg_fmt("  {n} deprecated rows deleted from {t}"))
    }
  }
}



