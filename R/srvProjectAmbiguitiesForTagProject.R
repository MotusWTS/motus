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
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvProjectAmbiguitiesForTagProject = function(projectID) {
    x = srvQuery(API=Motus$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT, params=list(projectID=projectID))
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
