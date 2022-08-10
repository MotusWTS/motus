#' Get tagIDs for ambiguous IDs
#'
#' Ambiguous IDs ("negative tag IDs") represent sets of 2 to 6 tags which cannot
#' be distinguished over some period of time.
#'
#' @param ambigIDs Integer vector. Negative ambiguous IDs
#'
#' @noRd

srvTagsForAmbiguities <- function(ambigIDs, verbose = FALSE) {
  srvQuery(API = motus_vars$API_TAGS_FOR_AMBIGUITIES, 
           params = list(ambigIDs = I(ambigIDs)), 
           verbose = verbose) %>%
    as.data.frame()
}
