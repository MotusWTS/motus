#' Plot all tags by site
#'
#' Plot tag ID vs time for all tags detected by site, coloured by antenna bearing
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for ts, antBearing, fullID, recvDepName
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags, or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Plot all sites within file for tbl file tbl.alltags
#' plotSite(tbl.alltags)
#' 
#' Plot only detections at a specific site; Piskwamish for data.frame df.alltags
#' plotSite(filter(df.alltags, recvDepName == "Piskwamish"))
#'
#' Plot only detections for specified tags for data.frame df.alltags
#' plotSite(filter(df.alltags, motusTagID %in% c(16047, 16037, 16039)))


plotSite <- function(data, sitename = unique(data$recvDepName)){
  data = data %>% mutate(hour = 3600*round(as.numeric(ts)/3600, 0)) ## round times to the hour
  #data <- filter_(data, paste("recvDepName", "==", "sitename"))
  data <- select(data, hour, antBearing, fullID, recvDepName) %>% distinct %>% collect %>% as.data.frame
  data$hour <- lubridate::as_datetime(data$hour, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(hour, fullID, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + 
    ggplot2::labs(title = "Detection Time vs Tag ID, coloured by antenna", x = NULL, y = "Tag ID", colour = "Antenna Bearing") +
    ggplot2::facet_wrap(~recvDepName) + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
