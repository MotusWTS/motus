#' Plot signal strength of all tags by a specified site
#'
#' Plot signal strength vs time for all tags detected at a specified site, coloured by antenna
#'
#' @param data dataframe of Motus detection data
#' @param sitename name of site
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' access the "all tags" table within the motus sql
#' tmp <- tbl(motusSqlFile, "alltags")
#' 
#' plot all tags for site Piskwamish
#' plotSiteSig(tmp, sitename = "Piskwamish")
#' 
#' Plot select tags for site Piskwamish 
#' plotSiteSig(filter(tmp, motusTagID %in% c(9045, 10234, 96321)), sitename = "Piskwamish")

plotSiteSig <- function(data, sitename){
  data <- filter_(data, paste("site", "==", "sitename"))
  data <- select(data, antBearing, ts, lat, sig, fullID, site) %>% distinct %>% collect %>% as.data.frame
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
    ggplot2::labs(title = paste0(sitename, ' tag detections by signal strength, coloured by antenna'), x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_wrap(~fullID) 
}
