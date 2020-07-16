#' Create dataframe for siteTrans function
#'
#' @param df dataframe of Motus detection data containing at a minimum fullID, ts, lat, lon
#'
#' @noRd

## site.fun and consec.fun adapted from "between.locs.R" script written by Phil
site.fun <- function(df) {
  df <- df[order(df$ts),] ## should already be in order, but just in case
  out.df.x <- df[1:(length(df$recvDeployName)-1), ]
  names(out.df.x) <- paste(names(df), "x", sep=".")
  out.df.y <- df[2:length(df$recvDeployName), ]
  names(out.df.y) <- paste(names(df), "y", sep=".")
  out.df <- cbind(out.df.x, out.df.y)
  out.df <- dplyr::filter(out.df, ((.data$recvDeployName.x != .data$recvDeployName.y)))
  return(out.df)
}
