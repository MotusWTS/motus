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
    tags = as.data.frame(x$tags),
    tagDeps = as.data.frame(x$tagDeps),
    tagProps = as.data.frame(x$tagProps),
    species = as.data.frame(x$species),
    projs = as.data.frame(x$projs)
  )
}
