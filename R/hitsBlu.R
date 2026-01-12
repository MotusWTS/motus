#' Add/update hitsBlu data
#' 
#' Download or resume a download of the 'hitsBlu' table in an existing Motus
#' database. `hitsBlu` contains information regarding the 'health' of portable
#' node units. 
#'
#' @inheritParams args
#' 
#' @details This function is only required if you suspect blu tag hits have been
#'   missed (due to hits being downloaded before the motus package had the 
#'   functionality to download blu tag hits).
#'   
#'   If an `hitsBlu` table doesn't exist, it will be created prior to
#'   downloading. If there is an existing `hitsBlu` table, this will update the
#'   records.
#'
#' @examples
#' \dontrun{
#'   hitsBlu(my_tags)
#' }
#' 
#' @export

hitsBlu <- function(src) {

  ensureDBTables(src, projRecv = get_projRecv(src))
    
  # Tag Project or Receiver?
  projdevID <- get_projRecv(src)
  if(is_proj(get_projRecv(src))) {
    srvHitsBluBatches <- srvHitsBluBatchesForTagProject
    hitsBlu <- hitsBluForBatchProject
  } else {
    srvHitsBluBatches <- srvHitsBluBatchesForReceiver
    hitsBlu <- hitsBluForBatchReceiver
    projdevID <- get_deviceID(src)
  }
  
  # Get batches to check ---------------------------
  message("Checking blu tag batch history...")

  # Downloaded batches with blu tag hit data
  blu_batches <- dplyr::tbl(src, "hitsBlu") %>%
    dplyr::pull(.data$batchID) %>%
    unique()
  
  # Downloaded batches, excluding those with known blu tag hits
  old_batches <- dplyr::tbl(src, "batches") %>%
    dplyr::filter(!.data$batchID %in% .env$blu_batches) %>%
    dplyr::pull(.data$batchID)
  
  # Get outstanding batches
  batches <- srvHitsBluBatches(
    projdevID,
    batchID = min(old_batches), 
    lastBatchID = max(old_batches)) %>%
    unlist(use.names = FALSE)
    
  batches <- batches[!batches %in% blu_batches] # Not already downloaded     
  
  # Announce
  message(msg_fmt("hitsBlu: {length(batches):5d} new batch records to check"))

  if(length(batches) > 0) {
    for(b in batches) {
      hitsBlu(
        src, 
        batchID = b, 
        batchMsg = msg_fmt("batchID {b:8d} (#{which(b == batches)} of {length(batches):6d})"), 
        projdevID)
    }
  }
  src
}
