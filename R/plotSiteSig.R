#' Plot signal strength of all tags by a specified site
#'
#' Plot signal strength vs time for all tags detected at a specified site, coloured by antenna
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for antBearing, ts, recvDeployLat, sig, fullID, recvDeployName
#' @param recvDeployName name of recvDeployName
#' @export
#'
#' @examples
#' # You can use either a selected tbl from .motus eg. "alltags", or a
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
#' tbl.alltags <- tbl(sql.motus, "alltags") 
#' 
#' # convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' df.alltags <- tbl.alltags %>% 
#'   collect() %>% 
#'   as.data.frame()
#' 
#' # Plot all tags for site Piskwamish
#' plotSiteSig(tbl.alltags, recvDeployName = "Piskwamish")
#' 
#' # Plot select tags for site Piskwamish 
#' plotSiteSig(filter(df.alltags, motusTagID %in% c(16037, 16039, 16035)), 
#'   recvDeployName = "Netitishi")

plotSiteSig <- function(data, recvDeployName){

  data <- data %>%
    dplyr::filter(recvDeployName == !!recvDeployName) %>%
    dplyr::select("antBearing", "ts", "recvDeployLat", "sig", "fullID", "recvDeployName") %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    dplyr::mutate(ts = lubridate::as_datetime(.data$ts, tz = "UTC"),
                  antBearing = as.factor(.data$antBearing))

  ggplot2::ggplot(data, ggplot2::aes_string("ts", "sig", col = "antBearing")) + 
    ggplot2::geom_point() + 
    ggplot2::theme_bw() + 
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) + 
    ggplot2::labs(title = paste0(recvDeployName, ' tag detections by signal strength, coloured by antenna'), 
                  x = "Date", y = "Signal Strength", colour = "Antenna Bearing") +
    ggplot2::facet_wrap("fullID") 
}
