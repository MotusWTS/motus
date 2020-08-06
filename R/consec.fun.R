#' Create dataframe for siteTrans function
#'
#' @param df dataframe of Motus detection data containing at a minimum fullID,
#'   ts, lat, lon
#'
#' @noRd


consec.fun <- function(df) {
  df <- df[order(df$ts),]
  a <- df$recvDeployName[-length(df$recvDeployName)]
  b <- df$recvDeployName[-1]
  tmp <- c(0, 1 - (as.numeric(a==b)))
  run <- cumsum(tmp)
  transitions <- which(diff(run) != 0)
  transitions <- c(transitions, transitions+1, length(df$recvDeployName))
  out.df <- df[transitions,]
  out.df <- out.df[order(out.df$ts),]
  return(out.df)
}

