#' Get the amount of data required to update a receiver project
#'
#' @param deviceID Integer. Device ID
#' @param batchID Integer. Largest `batchID` already owned for this project.
#'   Default: 0, meaning none.
#'
#' @noRd

srvSizeOfUpdateForReceiver <- function(deviceID, batchID = 0, verbose = FALSE) {
  srvQuery(API = motus_vars$API_SIZE_OF_UPDATE_FOR_RECEIVER, 
           params = list(deviceID = deviceID, batchID = batchID),
           verbose = verbose) %>%
    to_df()
}
