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
  a <- df$site[-length(df$site)]
  b <- df$site[-1]
  tmp <- c(0, 1 - (as.numeric(a==b)))
  run <- cumsum(tmp)
  transitions <- which(diff(run) != 0)
  transitions <- c(transitions, transitions+1, length(df$site))
  out.df <- df[transitions,]
  out.df <- out.df[order(out.df$ts),]
  return(out.df)
}

site.fun <- function(df) {
  df <- subset(df, select = -c(motusTagID, tagDeployID))
  df <- df[order(df$ts),] ## should already be in order, but just in case
  out.df.x <- df[1:(length(df$site)-1), ]
  names(out.df.x) <- paste(names(df), "x", sep=".")
  out.df.y <- df[2:length(df$site), ]
  names(out.df.y) <- paste(names(df), "y", sep=".")
  out.df <- cbind(out.df.x, out.df.y)
  out.df <- subset(out.df, ((site.x != site.y)))
  return(out.df)
}
