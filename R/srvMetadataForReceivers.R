#' Get the metadata for some receivers
#'
#' The receiver and antenna metadata are returned for any deployments
#' of the specified devices for which the user has project permissions
#' to, or which have made their receiver metadata public.
#'
#' @param deviceIDs Integer vector. Receiver IDs
#'
#' @noRd

srvMetadataForReceivers <- function(deviceIDs, verbose = FALSE) {
  x <- srvQuery(API = motus_vars$API_METADATA_FOR_RECEIVERS, 
                params = list(deviceIDs = I(deviceIDs)),
                verbose = verbose)
  list(
    recvDeps = as.data.frame(x$recvDeps),
    antDeps = as.data.frame(x$antDeps),
    projs = as.data.frame(x$projs)
  )
}
