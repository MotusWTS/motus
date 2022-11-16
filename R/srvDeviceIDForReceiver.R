#' Get the device ID for one or more receivers
#'
#' The `deviceID` is returned for any valid receiver serial numbers.
#'
#' @param serno Character vector. Receiver serial numbers, e.g.
#'   "SG-1234BBBK4321", "Lotek-123"
#'
#' @noRd

srvDeviceIDForReceiver <- function(serno, verbose = FALSE) {
  srvQuery(API = motus_vars$API_DEVICE_ID_FOR_RECEIVER, 
           params = list(serno = I(serno)),
           verbose = verbose) %>%
    to_df()
}
