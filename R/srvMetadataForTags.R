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
    tags = as.data.frame(x$tags),
    tagDeps = as.data.frame(x$tagDeps),
    tagProps = as.data.frame(x$tagProps),
    species = as.data.frame(x$species),
    projs = as.data.frame(x$projs)
  )
}
