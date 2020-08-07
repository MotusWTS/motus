#' get the hits for a receiver from the data server
#'
#' @param batchID integer scalar motus batch ID
#' @param hitID integer scalar ID of latest hit already obtained.
#' Default: 0, meaning none.
#'
#' @return data.frame with these columns:
#' \itemize{
#'   \item hitID
#'   \item runID
#'   \item batchID
#'   \item ts
#'   \item sig
#'   \item sigSD
#'   \item noise
#'   \item freq
#'   \item freqSD
#'   \item slop
#'   \item burstSlop
#' }
#'
#' @noRd

srvHitsForReceiver = function(batchID, hitID=0, verbose = FALSE) {
    x = srvQuery(API=motus_vars$API_HITS_FOR_RECEIVER, 
                 params=list(batchID=batchID, hitID=hitID),
                 verbose = verbose)
    return (structure(x, class = "data.frame", row.names=seq(along=x[[1]])))
}
