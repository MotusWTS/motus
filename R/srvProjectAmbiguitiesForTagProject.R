#' get the project ambiguities for a tag project from the data server
#'
#' @param projectID integer scalar motus project ID
#'
#' @return data.frame with these columns:
#' \itemize{
#' \item ambigProjectID integer negative project ambiguity ID
#' which represents a unique set of project IDs sharing at least
#' one ambiguous tag detection
#' \item projectID1 motus project ID
#' \item projectID2 motus project ID
#' \item projectID3 motus project ID
#' \item projectID4 motus project ID
#' \item projectID5 motus project ID
#' \item projectID6 motus project ID
#' }
#'
#' @noRd

srvProjectAmbiguitiesForTagProject <- function(projectID, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT,
                params = list(projectID = projectID),
                verbose = verbose)
  structure(x, class = "data.frame", row.names = seq(along = x[[1]]))
}
