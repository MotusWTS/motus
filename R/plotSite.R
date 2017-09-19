#' Plot all tags by site
#'
#' Plot tag ID vs time for all tags detected by site, coloured by antenna bearing
#'
#' @param data tbl file of .motus data
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' access the "all tags" table within the motus sql
#' tmp <- tbl(motusSqlFile, "alltags")
#' 
#' Plot all sites within file
#' plotSite(tmp)
#' 
#' Plot only detections at a specific site; Piskwamish
#' plotSite(filter(tmp, site == "Piswamish"))
#'
dataGrouped <- filter_(data, paste(lat.name, "!=", 0)) %>% group_by(site) %>% 
  
plotSite <- function(data, sitename = unique(data$site)){
  data = data %>% mutate(hour = 3600*round(ts/3600, 0)) ## round times to the hour
  #data <- filter_(data, paste("site", "==", "sitename"))
  data <- select(data, hour, antBearing, fullID, site) %>% distinct %>% collect %>% as.data.frame
  data$hour <- lubridate::as_datetime(data$hour, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(hour, fullID, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + 
    ggplot2::labs(title = "Detection Time vs Tag ID, coloured by antenna", x = NULL, y = "Tag ID", colour = "Antenna Bearing") +
    ggplot2::facet_wrap(~site) + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
