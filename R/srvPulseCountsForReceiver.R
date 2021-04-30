#' get the pulse counts for an antenna from the data server
#'
#' Pulse counts summarize antenna activity on an hourly basis.
#'
#' @param batchID integer scalar batch ID
#' @param ant integer antenna
#' @param hourBin hour bin, i.e. \code{floor(timestamp/3600)} for the
#' pulses in this bin.  Default: 0, meaning no pulse counts have been
#' obtained for this batch.  When 0, \code{ant} is ignored
#'
#' @return data.frame with these columns:
#' \itemize{
#'    \item batchID  integer batch ID
#'    \item ant      integer antenna number
#'    \item hourBin  numeric hour indicator given as \code{floor(timestamp / 3600)}
#'    \item count    integer number of pulses seen by antenna in this hour bin
#' }
#'
#' @noRd
#'
#' @note Paging for this query is handled by passing the last ant and hourBin values
#' received to the next call of this function.  Values are returned sorted by
#' \code{hourBin} \emph{within} \code{ant} for each batchID.

srvPulseCountsForReceiver <- function(batchID, ant, hourBin = 0, verbose = FALSE) {
    x <- srvQuery(API = motus_vars$API_PULSE_COUNTS_FOR_RECEIVER, 
                 params = list(batchID = batchID, ant = ant, hourBin = hourBin),
                 verbose = verbose)
    structure(x, class = "data.frame", row.names = seq(along = x[[1]]))
}
