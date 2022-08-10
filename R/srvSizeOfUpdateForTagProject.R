#' Get the amount of data required to update a tag project
#'
#' @param projectID Integer. Project ID
#' @param batchID Integer. Largest `batchID` already owned for this project.
#'   Default: 0, meaning none.
#'
#' @noRd

srvSizeOfUpdateForTagProject <- function(projectID, batchID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_SIZE_OF_UPDATE_FOR_TAG_PROJECT, 
           params = list(projectID = projectID, batchID = batchID),
           verbose = verbose) %>%
    as.data.frame()
}
