#' Get the hits for a tag project
#'
#' @param projectID Integer. Motus project ID
#' @param batchID Integer. Batch ID
#' @param hitID Integer. Hit ID of latest hit already obtained. Default: 0,
#'   meaning none.
#'
#' @noRd

srvHitsForTagProject <- function(projectID, batchID, hitID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_HITS_FOR_TAG_PROJECT, 
           params = list(projectID = projectID, batchID = batchID, 
                         hitID = hitID),
           verbose = verbose) %>%
    to_df()
}
