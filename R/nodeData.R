#' Add/update nodeData
#' 
#' Download or resume a download of the 'nodeData' table in an existing Motus
#' database. `nodeData` contains information regarding the 'health' of portable
#' node units. 
#'
#' @inheritParams args
#' 
#' @details This function is automatically run by the [tagme()] function with
#'   `resume = TRUE`. 
#'   
#'   If an `nodeData` table doesn't exist, it will be created prior to
#'   downloading. If there is an existing `nodeData` table, this will update the
#'   records.
#'   
#'   Note that only records for CTT tags will have the possibility of
#' `nodeData`. 
#' 
#'   Node metadata is found in the `nodeDeps` table, updated along with other
#'   metadata.
#'
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#'   
#' # Access `nodeData` table
#' library(dplyr)
#' a <- tbl(sql_motus, "nodeData")
#'   
#' # If you just want to download `nodeData`
#' \dontrun{my_tags <- nodeData(sql_motus)}
#'
#' @export

nodeData <- function(src, resume = FALSE) {
  
  getBatches <- function(src) {
    dplyr::tbl(src, "batches") %>%
      dplyr::filter(.data$source == "ctt") %>%
      dplyr::pull(.data$batchID)
  }
  
  pageInitial <- function(batchID, projectID) {
    srvNodes(batchID = batchID, projectID = projectID)
  }
  
  pageForward <- function(b, batchID, projectID) {
    # Page forward
    nodeDataID <- b$nodeDataID[nrow(b)]
    
    # Try again
    srvNodes(batchID = batchID, projectID = projectID, nodeDataID = nodeDataID) 
  }
  
  pageDataByBatch(src, table = "nodeData", resume = resume,
                  getBatches, pageInitial, pageForward)
  
}