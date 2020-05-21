#' Plot signal strength of all detections for a specified tag by site
#'
#' Plot signal strength vs time for specified tag, faceted by site (ordered by latitude) and coloured by antenna
#'
#' @param data a selected table from .motus data, eg. "alltagsGPS", or a
#'   data.frame of detection data including at a minimum variables for
#'   motusTagID, sig, ts, antBearing, recvDeployLat, fullID, recvDeployName,
#'   gpsLat, gpsLon
#' @param motusTagID a numeric motusTagID to display in plot
#' @export
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
#' # Plot signal strength of a specified tag using dataframe df.alltags
#' plotTagSig(df.alltags, motusTagID = 16047)
#' 
#' # Plot signal strength of a specified tag using tbl file tbl.alltags
#' plotTagSig(tbl.alltags, motusTagID = 16035)

plotTagSig <- function(data, motusTagID){
  tag.id <- motusTagID
  data <- data %>% 
    dplyr::filter(.data$motusTagID == !!tag.id) %>%
    dplyr::select("motusTagID", "sig", "ts", "antBearing", "recvDeployLat", "recvDeployLon", 
                  "gpsLat", "gpsLon", "fullID", "recvDeployName") %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>%
    dplyr::mutate(recvLat = dplyr::if_else((is.na(.data$gpsLat)|.data$gpsLat == 0|.data$gpsLat ==999),
                                           .data$recvDeployLat,
                                           .data$gpsLat),
                  recvLon = dplyr::if_else((is.na(.data$gpsLon)|.data$gpsLon == 0|.data$gpsLon == 999),
                                           .data$recvDeployLon,
                                           .data$gpsLon),
                  recvDeployName = paste0(.data$recvDeployName, "\n",
                                          round(.data$recvLat, digits = 1), ", ",
                                          round(.data$recvLon, digits = 1)),
                  ts = lubridate::as_datetime(.data$ts, tz = "UTC"),
                  ## order recvDeployName by latitude
                  recvDeployName = stats::reorder(.data$recvDeployName, .data$recvLat),
                  antBearing = as.factor(.data$antBearing)) 

  ggplot2::ggplot(data, ggplot2::aes_string(x = "ts", y = "sig", col = "antBearing")) +
    ggplot2::geom_point() + 
    ggplot2::theme_bw() + 
    ggplot2::labs(title = paste("Detection Time vs Signal Strength, coloured by antenna \n ID ", motusTagID), 
                  x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_grid(rows = "recvDeployName") + 
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}
