#' Get the project ambiguities for a tag project
#'
#' @param projectID Integer. Project ID
#'
#' @noRd

srvProjectAmbiguitiesForTagProject <- function(projectID, verbose = FALSE) {
  srvQuery(API = motus_vars$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT,
           params = list(projectID = projectID),
           verbose = verbose) %>%
    as.data.frame()
}
