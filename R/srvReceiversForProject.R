#' Get the list of receiver deployments for a project
#'
#' The metadata are returned for any deployments of a receiver by the specified
#' project, provided the user has permissions to the project.
#'
#' @param projectID Integer. Project ID
#'
#' @noRd

srvReceiversForProject <- function(projectID, verbose = FALSE) {
  srvQuery(API = motus_vars$API_RECEIVERS_FOR_PROJECT, 
           params = list(projectID = projectID), 
           verbose = verbose) %>%
    to_df()
}
