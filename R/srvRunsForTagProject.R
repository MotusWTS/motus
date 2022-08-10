#' Get the runs for a tag project in a batch
#'
#' @param projectID Integer. Project ID
#' @param batchID Integer. Batch ID
#' @param runID Integer. ID of latest run already obtained. Default: 0, meaning
#'   none.
#'
#' @noRd

srvRunsForTagProject <- function(projectID, batchID, runID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_RUNS_FOR_TAG_PROJECT, 
           params = list(projectID = projectID, 
                         batchID = batchID, 
                         runID = runID),
           verbose = verbose) %>%
    as.data.frame()
}
