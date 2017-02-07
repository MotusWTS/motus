#' Plot signal strength of all tags at a specified site
#'
#' Plot signal strength vs time for all tags detected at a specified site, coloured by antenna
#'
#' @param data dataframe of Motus detection data
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' plotSiteSig(dat, sitename = "Piskwamish")

plotSiteSig <- function(data, sitename = unique(data$site)){
  data$ant <- sub("\\s+$", "", dat$ant) ## remove blank spaces at the end of some antenna values
  data <- unique(subset(data, select = c(ts, sig, ant, fullID), site == sitename)) ## get unique hourly detections for small dataframe
  p <- ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = ant))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::labs(title = "Detection Time vs Signal Strength by Tag ID, coloured by antenna", x = "Date", y = "Signal Strength", colour = "Antenna") +
    ggplot2::facet_wrap(~fullID)
}
