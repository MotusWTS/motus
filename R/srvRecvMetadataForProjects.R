#' Get the metadata for entire projects
#'
#' The receiver and antenna metadata are returned for any deployments of the
#' specified devices for which the user has project permissions to, or which
#' have made their receiver metadata public.
#'
#' @param projectIDs Integer vector. Project IDs
#'
#' @noRd

srvRecvMetadataForProjects <- function(projectIDs, verbose = FALSE) {

  if(!is.null(projectIDs)) projectIDs <- I(projectIDs)
  
  x <- srvQuery(API = motus_vars$API_RECV_METADATA_FOR_PROJECTS,
               params = list(projectIDs = projectIDs),
               verbose = verbose)

  list(
    recvDeps = as.data.frame(x$recvDeps),
    antDeps = as.data.frame(x$antDeps),
    nodeDeps = as.data.frame(x$nodeDeps),
    projs = as.data.frame(x$projs)
  )
}
