#' get node data from the data server
#' 
#' Functions for a project OR receiver. If `projectID` is suppled, returns project
#' `nodeData.`
#'
#' @param batchID Integer. Batch ID
#' @param projectID Integer. Optional motus tag project ID
#' @param id Numeric. `nodeData` ID of latest fix already owned. Default: 0,
#'   meaning none.
#'
#' @return data.frame with these columns:
#' - id            numeric nodeData ID
#' - batchID       integer batch ID
#' - ts            numeric system timestamp
#' - nodeNum       character node number
#' - ant           character antenna number/id
#' - sig           numeric
#' - battery       numeric
#' - temperature   numeric
#' 
#' @noRd

srvNodes = function(batchID, projectID = NULL, id = 0) {
  if(is.null(projectID)) {
    x <- srvQuery(API = motus_vars$API_NODES_FOR_RECEIVER, 
                  params = list(batchID = batchID, 
                                id = id))
  } else {
    x <- srvQuery(API = motus_vars$API_NODES_FOR_TAG_PROJECT, 
                  params = list(projectID = projectID, 
                                batchID = batchID, 
                                id = id))
  }
  return (structure(x, class = "data.frame", row.names = seq(along = x[[1]])))
}
