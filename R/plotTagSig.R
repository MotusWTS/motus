#' Plot signal strength of all detections for a specified tag by site
#'
#' Plot signal strength vs time for specified tag, faceted by site (ordered by latitude) and coloured by antenna
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, sig, ts, antBearing, recvDeployLat, fullID, recvDepName
#' @param motusTagID a numeric motusTagId to display in plot
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags, or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Plot signal strength of a specified tag using dataframe df.alltags
#' plotTagSig(df.alltags, motusTagID = 16047)
#' 
#' Plot signal strength of a specified tag using tbl file tbl.alltags
#' plotTagSig(tbl.alltags, motusTagID = 16035)

plotTagSig <- function(data, motusTagID){
  tag.id <- motusTagID
  data <- filter_(data, paste("motusTagID", "==", "tag.id"))
  data <- select(data, motusTagID, sig, ts, antBearing, recvDeployLat, fullID, recvDepName) %>% distinct %>% collect %>% as.data.frame
  data <- within(data, recvDepName <- reorder(recvDepName, (recvDeployLat))) ## order recvDepName by latitude
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  p <- ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = as.factor(antBearing)))
  p + ggplot2::geom_point() + ggplot2::theme_bw() + ggplot2::labs(title = paste("Detection Time vs Signal Strength, coloured by antenna \n ID ", motusTagID), x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_grid(recvDepName~.) + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
