#' Plot all tags at a specified site
#'
#' Plot tag ID vs time for all tags detected at a specified site, coloured by antenna
#'
#' @param data dataframe of Motus detection data
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' plotSite(dat, sitename = "Piskwamish")

plotSite <- function(data, sitename = unique(data$site)){
  data$round_ts <- as.POSIXct(round(data$ts, "hours")) ## round to the hour
  data$ant <- sub("\\s+$", "", dat$ant) ## remove blank spaces at the end of some antenna values
  data <- unique(subset(data, select = c(round_ts, ant, fullID), site == sitename)) ## get unique hourly detections for small dataframe
  p <- ggplot2::ggplot(data, ggplot2::aes(round_ts, fullID, col = ant))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::labs(title = "Detection Time vs Tag ID, coloured by antenna", x = "Date", y = "Tag ID", colour = "Antenna")
}
