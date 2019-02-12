#' Plot signal strength of all tags by a specified site
#'
#' Plot signal strength vs time for all tags detected at a specified site, coloured by antenna
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for antBearing, ts, recvDeploylat, sig, fullID, recvDeployName
#' @param recvDeployName name of recvDeployName
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags", or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' plot all tags for site Piskwamish
#' plotSiteSig(tbl.alltags, recvDeployName = "Piskwamish")
#' 
#' Plot select tags for site Piskwamish 
#' plotSiteSig(filter(df.alltags, motusTagID %in% c(16037, 16039, 16035)), recvDeployName = "Netitishi")

plotSiteSig <- function(data, recvDeployName){

  data <- data %>%
    dplyr::filter(recvDeployName == !!recvDeployName) %>%
    dplyr::select(antBearing, ts, recvDeployLat, sig, fullID, recvDeployName) %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    dplyr::mutate(ts = lubridate::as_datetime(ts, tz = "UTC"))
  
  ggplot2::ggplot(data, ggplot2::aes(ts, sig, col = as.factor(antBearing))) + 
    ggplot2::geom_point() + 
    ggplot2::theme_bw() + 
    ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
    ggplot2::labs(title = paste0(recvDeployName, ' tag detections by signal strength, coloured by antenna'), 
                  x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_wrap(~fullID) 
}
