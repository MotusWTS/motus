#' Fetch deprecated batches for a tag project
#'
#' @param projectID Numeric. Motus project ID
#' @param batchID Numeric. Largest batchID already fetched. For pagination,
#'   starts with 0 (default).
#' @param verbose Logical. Whether or not to make a verbose query.
#'
#' @noRd

srvBatchesForTagProjectDeprecated <- function(projectID, batchID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_BATCHES_FOR_TAG_PROJECT_DEPRECATED, 
           params = list(projectID = projectID, batchID = batchID),
           verbose = verbose) %>%
    as.data.frame()
}
