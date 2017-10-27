#' Plot signal strength of all detections for a specified tag by site
#'
#' Plot signal strength vs time for specified tag, faceted by site (ordered by latitude) and coloured by antenna
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables motusTagID, sig, ts, antBearing, lat, fullID, site
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either the tbl or the flat format for the siteTrans function, instructions to convert
#' a .motus file to both formats is below.
#' To access any tbl from .motus data saved on your computer:
#' file.name <- "data/project-sample.motus" ## replace with the full location of the sample dataset or your own project-XX.motus file
#' tmp <- dplyr::src_sqlite(file.name)
#' alltags <- tbl(motusSqlFile, "alltags")
#' 
#' To convert tbl to flat format:
#' alltags <- alltags %>% collect %>% as.data.frame
#' 
#' Plot signal strength of a specified tag
#' plotTagSig(alltags, tag.id = 16047)
#' 


plotTagSig <- function(data, tag.id){
  data <- select(data, motusTagID, sig, ts, antBearing, lat, fullID, site) %>% filter_(paste("motusTagID", "==", "tag.id")) %>% distinct %>% collect %>% as.data.frame
  data <- within(data, site <- reorder(site, (lat))) ## order site by latitude
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::labs(title = paste("Detection Time vs Signal Strength, coloured by antenna \n ID ", tag.id), x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_grid(site~.) + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
