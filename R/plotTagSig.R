#' Plot signal strength of all detections for a specified tag by site
#'
#' Plot signal strength vs time for specified tag, faceted by site (ordered by latitude) and coloured by antenna
#'
#' @param data dataframe of Motus detection data
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' access the "all tags" table within the motus sql
#' tmp <- tbl(motusSqlFile, "alltags")
#' 
#' Plot signal strength of a specified tag
#' plotTagSig(tmp, tag.id = 17367)
#' 


plotTagSig <- function(data, tag.id){
  data <- select(data, motusTagID, sig, ts, antBearing, lat, fullID, site) %>% filter_(paste("motusTagID", "==", "tag.id")) %>% distinct %>% collect %>% as.data.frame
  data <- within(data, site <- reorder(site, (lat))) ## order site by latitude
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::labs(title = paste("Detection Time vs Signal Strength, coloured by antenna \n ID ", tag.id), x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_grid(site~.) + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
