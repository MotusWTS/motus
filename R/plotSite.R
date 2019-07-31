#' Plot all tags by site
#'
#' Plot tag ID vs time for all tags detected by site, coloured by antenna bearing
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for ts, antBearing, fullID, recvDeployName
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' # You can use either a selected tbl from .motus eg. "alltags", or a
#' # data.frame, instructions to convert a .motus file to all formats are below.
#'
#' # download and access data from project 176 in sql format
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#' 
#' # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' library(dplyr)
#' tbl.alltags <- tbl(sql.motus, "alltags") 
#' 
#' # convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' df.alltags <- tbl.alltags %>% 
#'   collect() %>% 
#'   as.data.frame()
#' 
#' # Plot all sites within file for tbl file tbl.alltags
#' plotSite(tbl.alltags)
#' 
#' # Plot only detections at a specific site; Piskwamish for data.frame
#' # df.alltags
#' plotSite(filter(df.alltags, recvDeployName == "Piskwamish"))
#'
#' #Plot only detections for specified tags for data.frame df.alltags
#' plotSite(filter(df.alltags, motusTagID %in% c(16047, 16037, 16039)))


plotSite <- function(data, sitename = unique(data$recvDeployName)){
  data = data %>% mutate(hour = 3600*round(as.numeric(ts)/3600, 0)) ## round times to the hour
  data <- select(data, hour, antBearing, fullID, recvDeployName, recvDeployLat, recvDeployLon,
                 gpsLat, gpsLon) %>% distinct %>% collect %>% as.data.frame
  data <- mutate(data,
                 recvLat = if_else((is.na(gpsLat)|gpsLat == 0|gpsLat ==999),
                                   recvDeployLat,
                                   gpsLat),
                 recvLon = if_else((is.na(gpsLon)|gpsLon == 0|gpsLon == 999),
                                   recvDeployLon,
                                   gpsLon),
                 recvDeployName = paste(recvDeployName, 
                                        round(recvLat, digits = 1), sep = "\n" ),
                 recvDeployName = paste(recvDeployName,
                                        round(recvLon, digits = 1), sep = ", "),
                 hour = lubridate::as_datetime(hour, tz = "UTC"))
  p <- ggplot2::ggplot(data, ggplot2::aes(hour, fullID, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + 
    ggplot2::labs(title = "Detection Time vs Tag ID, coloured by antenna", x = NULL, y = "Tag ID", colour = "Antenna Bearing") +
    ggplot2::facet_wrap(~recvDeployName) + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
