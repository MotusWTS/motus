#' Plot signal strength of all tags by a specified site
#'
#' Plot signal strength vs time for all tags detected at a specified site,
#' coloured by antenna
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame
#'   of detection data including at a minimum variables for `antBearing`, `ts`,
#'   `recvDeployLat`, `sig`, `fullID`, `recvDeployName`
#' @param recvDeployName name of `recvDeployName`
#' @export
#'
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#' 
#' # convert sql file "sql_motus" to a tbl called "tbl_alltags"
#' library(dplyr)
#' tbl_alltags <- tbl(sql_motus, "alltags") 
#' 
#' # convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
#' df_alltags <- tbl_alltags %>% 
#'   collect() %>% 
#'   as.data.frame()
#' 
#' # Plot all tags for site Piskwamish
#' plotSiteSig(tbl_alltags, recvDeployName = "Piskwamish")
#' 
#' # Plot select tags for site Piskwamish 
#' plotSiteSig(filter(df_alltags, motusTagID %in% c(16037, 16039, 16035)), 
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
