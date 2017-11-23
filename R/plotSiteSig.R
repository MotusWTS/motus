#' Plot signal strength of all tags by a specified site
#'
#' Plot signal strength vs time for all tags detected at a specified site, coloured by antenna
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables antBearing, ts, lat, sig, fullID, recvDepName
#' @param sitename name of recvDepName
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
#' plot all tags for site Piskwamish
#' plotSiteSig(alltags, sitename = "Piskwamish")
#' 
#' Plot select tags for site Piskwamish 
#' plotSiteSig(filter(alltags, motusTagID %in% c(16037, 16039, 16035)), sitename = "Netitishi")

plotSiteSig <- function(data, sitename){
  data <- filter_(data, paste("recvDepName", "==", "sitename"))
  data <- select(data, antBearing, ts, recvDeployLat, sig, fullID, recvDepName) %>% distinct %>% collect %>% as.data.frame
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
    ggplot2::labs(title = paste0(sitename, ' tag detections by signal strength, coloured by antenna'), x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_wrap(~fullID) 
}
