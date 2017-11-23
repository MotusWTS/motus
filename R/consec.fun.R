#' Create dataframe for siteTrans function
#'
#' @param data dataframe of Motus detection data containing at a minimum fullID, ts, lat, lon
#'
#' @export
#'
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'

## site.fun and consec.fun adapted from "between.locs.R" script written by Phil

consec.fun <- function(df) {
  df <- df[order(df$ts),]
  a <- df$recvDepName[-length(df$recvDepName)]
  b <- df$recvDepName[-1]
  tmp <- c(0, 1 - (as.numeric(a==b)))
  run <- cumsum(tmp)
  transitions <- which(diff(run) != 0)
  transitions <- c(transitions, transitions+1, length(df$recvDepName))
  out.df <- df[transitions,]
  out.df <- out.df[order(out.df$ts),]
  return(out.df)
}

