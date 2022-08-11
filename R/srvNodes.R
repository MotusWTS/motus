#' Get node data from the data server
#' 
#' Functions for a project OR receiver. If `projectID` is suppled, returns project
#' `nodeData.`
#'
#' @param batchID Integer. Batch ID
#' @param projectID Integer. Optional motus tag project ID
#' @param id Numeric. `nodeData` ID of latest fix already owned. Default: 0,
#'   meaning none.
#' 
#' @noRd

srvNodes <- function(batchID, projectID = NULL, nodeDataID = 0, verbose = FALSE) {

  if(is.null(projectID)) {
    x <- srvQuery(API = motus_vars$API_NODES_FOR_RECEIVER, 
                  params = list(batchID = batchID, 
                                nodeDataID = nodeDataID),
                  verbose = verbose)
  } else {
    x <- srvQuery(API = motus_vars$API_NODES_FOR_TAG_PROJECT, 
                  params = list(projectID = projectID, 
                                batchID = batchID, 
                                nodeDataID = nodeDataID),
                  verbose = verbose)
  }
  
  to_df(x)
}
