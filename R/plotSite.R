#' Plot all tags by site
#'
#' Plot tag ID vs time for all tags detected by site, coloured by antenna
#' bearing
#'
#' @param sitename Character vector. Subset of sites to plot. If `NULL`, all
#'   unique sites are plotted.
#'   
#' @inheritParams args
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
#' tbl_alltags <- tbl(sql_motus, "alltagsGPS") 
#' 
#' # convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
#' df_alltags <- tbl_alltags %>% 
#'   collect()
#' 
#' # Plot all sites within file for tbl file tbl_alltags
#' plotSite(tbl_alltags)
#' 
#' # Plot only detections at a specific site; Piskwamish for data.frame
#' # df_alltags
#' plotSite(filter(df_alltags, recvDeployName == "Piskwamish"))
#'
#' #Plot only detections for specified tags for data.frame df_alltags
#' plotSite(filter(df_alltags, motusTagID %in% c(16047, 16037, 16039)))
#'
#' @export

plotSite <- function(df, sitename = NULL, data) {
  
  if(!missing(data)) {
    warning("`data` is deprecated in favour of `df`)", call. = FALSE)
    df <- data
  }
  
  if(is.null(sitename)) sitename <- unique(df$recvDeployName)
  
  df <- df %>%  
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
                  antBearing = as.factor(.data$antBearing))
  
  ggplot2::ggplot(df, ggplot2::aes(x = .data[["hour"]], y = .data[["fullID"]], col = .data[["antBearing"]])) +
    ggplot2::geom_point() + 
    ggplot2::theme_bw() + 
    ggplot2::labs(title = "Detection Time vs Tag ID, coloured by antenna", 
                  x = NULL, y = "Tag ID", colour = "Antenna Bearing") +
    ggplot2::facet_wrap("recvDeployName") + 
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}
