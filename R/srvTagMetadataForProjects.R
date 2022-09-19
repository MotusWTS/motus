#' Get the tag metadata for some projects
#'
#' The basic tag and deployment metadata are returned for any deployments the
#' user has project permissions to, or which have made their tag metadata
#' public.
#'
#' @param projectIDs Integer vector. Project IDs
#'
#' @noRd

srvTagMetadataForProjects <- function(projectIDs, verbose = FALSE) {

  if(!is.null(projectIDs)) projectIDs <- I(projectIDs)
  
  x <- srvQuery(API = motus_vars$API_TAG_METADATA_FOR_PROJECTS, 
               params = list(projectIDs = projectIDs),
               verbose = verbose)
  
  list(
    tags = to_df(x$tags),
    tagDeps = to_df(x$tagDeps),
    tagProps = to_df(x$tagProps),
    species = to_df(x$species),
    projs = to_df(x$projs)
  )
}
