#' Plot signal strength of all detections for a specified tag by site
#'
#' Plot signal strength vs time for specified tag, faceted by site (ordered by latitude) and coloured by antenna
#'
#' @param data dataframe of Motus detection data
#' @export
#' @examples
#' plotTagSig(dat, tag = 171)

plotTagSig <- function(data, tag){
  data$ant <- sub("\\s+$", "", dat$ant) ## remove blank spaces at the end of some antenna values
  data <- within(data, site <- reorder(site, (lat))) ## order site by latitude
  data <- unique(subset(data, select = c(ts, sig, ant, id, site), id == tag)) ## get unique hourly detections for small dataframe
  p <- ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = ant))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::labs(title = paste("Detection Time vs Signal Strength, coloured by antenna \n ID ", tag), x = "Date", y = "Signal Strength", colour = "Antenna") +
    ggplot2::facet_grid(site~.)
}
