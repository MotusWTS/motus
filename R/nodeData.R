#' Add/update nodeData
#' 
#' Download or resume a download of the 'nodeData' table in an existing Motus
#' database. `nodeData` contains information regarding the 'health' of portable
#' node units. 
#'
#' @param src src_sqlite object representing the database
#' @param resume Logical. Resume a download? Otherwise the `nodeData` table is
#'   removed and the download is started from the beginning.
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
#' 
#' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#'   
#' # Access `nodeData` table
#' library(dplyr)
#' a <- tbl(sql.motus, "nodeData")
#'   
#' # If you just want to download `nodeData`
#' \dontrun{my_tags <- nodeData(sql.motus)}
#'
#' @export

nodeData <- function(src, resume = FALSE) {
  
  getBatches <- function(src) {
    dplyr::tbl(src$con, "batches") %>%
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