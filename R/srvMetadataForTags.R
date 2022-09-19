#' Get the metadata for some tags
#'
#' The basic tag and deployment metadata are returned for any
#' deployments the user has project permissions to, or which have
#' made their tag metadata public.
#'
#' @param motusTagIDs Integer vector. Tag IDs
#'
#' @noRd

srvMetadataForTags <- function(motusTagIDs, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_METADATA_FOR_TAGS, 
                params = list(motusTagIDs = I(motusTagIDs)),
                verbose = verbose)
  list(
    tags = to_df(x$tags),
    tagDeps = to_df(x$tagDeps),
    tagProps = to_df(x$tagProps),
    species = to_df(x$species),
    projs = to_df(x$projs)
  )
}
