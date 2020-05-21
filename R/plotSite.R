#' Plot all tags by site
#'
#' Plot tag ID vs time for all tags detected by site, coloured by antenna bearing
#'
#' @param data a selected table from .motus data, eg. "alltagsGPS", or a
#'   data.frame of detection data including at a minimum variables for ts,
#'   antBearing, fullID, recvDeployName
#' @param sitename Character vector. Which sites to plot? Defaults to all unique
#'   sites.
#'
#' @examples
#' # You can use either a selected tbl from .motus eg. "alltagsGPS", or a
#' # data.frame, instructions to convert a .motus file to all formats are below.
#'
#' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#' 
#' # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' library(dplyr)
#' tbl.alltags <- tbl(sql.motus, "alltagsGPS") 
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
#'
#' @export

plotSite <- function(data, sitename = unique(data$recvDeployName)){
  data <- data %>%  
    dplyr::mutate(hour = 3600*round(as.numeric(.data$ts)/3600, 0))  %>% ## round times to the hour
    dplyr::select("hour", "antBearing", "fullID", "recvDeployName", "recvDeployLat", "recvDeployLon",
                  "gpsLat", "gpsLon") %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    dplyr::mutate(recvLat = dplyr::if_else((is.na(.data$gpsLat)|.data$gpsLat == 0|.data$gpsLat ==999),
                                           .data$recvDeployLat,
                                           .data$gpsLat),
                  recvLon =  dplyr::if_else((is.na(.data$gpsLon)|.data$gpsLon == 0|.data$gpsLon == 999),
                                            .data$recvDeployLon,
                                            .data$gpsLon),
                  recvDeployName = paste(.data$recvDeployName, 
                                         round(.data$recvLat, digits = 1), sep = "\n" ),
                  recvDeployName = paste(.data$recvDeployName,
                                         round(.data$recvLon, digits = 1), sep = ", "),
                  hour = lubridate::as_datetime(.data$hour, tz = "UTC"),
                  antBearing = as.factor(.data$antBearing)) %>%
    as.data.frame()
  
  ggplot2::ggplot(data, ggplot2::aes_string(x = "hour", y = "fullID", col = "antBearing")) +
    ggplot2::geom_point() + 
    ggplot2::theme_bw() + 
    ggplot2::labs(title = "Detection Time vs Tag ID, coloured by antenna", 
                  x = NULL, y = "Tag ID", colour = "Antenna Bearing") +
    ggplot2::facet_wrap("recvDeployName") + 
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}
