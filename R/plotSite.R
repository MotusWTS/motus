#' Plot all tags by site
#'
#' Plot tag ID vs time for all tags detected by site, coloured by antenna bearing
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables ts, antBearing, fullID, site
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
#' Plot all sites within file
#' plotSite(alltags)
#' 
#' Plot only detections at a specific site; Piskwamish
#' plotSite(filter(alltags, site == "Piskwamish"))
#'
#' Plot only detections for specified tags
#' plotSite(filter(alltags, motusTagID %in% c(16047, 16037, 16039)))


plotSite <- function(data, sitename = unique(data$site)){
  data = data %>% mutate(hour = 3600*round(as.numeric(ts)/3600, 0)) ## round times to the hour
  #data <- filter_(data, paste("site", "==", "sitename"))
  data <- select(data, hour, antBearing, fullID, site) %>% distinct %>% collect %>% as.data.frame
  data$hour <- lubridate::as_datetime(data$hour, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(hour, fullID, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + 
    ggplot2::labs(title = "Detection Time vs Tag ID, coloured by antenna", x = NULL, y = "Tag ID", colour = "Antenna Bearing") +
    ggplot2::facet_wrap(~site) + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
