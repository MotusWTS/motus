#' get the motus tagIDs for amibiguity IDs
#'
#' Ambiguity IDs ("negative tag IDs") represent sets of 2 to 6 motus tags
#' which cannot be distinguished over some period of time.
#'
#' @param ambigIDs integer vector of negative ambiguity IDs
#'
#' @return a data.frame with these columns:
#' \itemize{
#'    \item ambigID; negative integer tag ambiguity ID
#'    \item motusTagID1; positive integer motus tag ID
#'    \item motusTagID2; positive integer motus tag ID
#'    \item motusTagID3; positive integer motus tag ID or NA
#'    \item motusTagID4; positive integer motus tag ID or NA
#'    \item motusTagID5; positive integer motus tag ID or NA
#'    \item motusTagID6; positive integer motus tag ID or NA
#' }
#' with one row per ambigID
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvTagsForAmbiguities = function(ambigIDs) {
    x = srvQuery(API=Motus$API_TAGS_FOR_AMBIGUITIES, params=list(ambigIDs=ambigIDs))
    return(structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
