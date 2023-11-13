#' Plot all tags by site
#'
#' Plot tag ID vs time for all tags detected by site, coloured by antenna
#' bearing. Input is expected to be a data frame, database table, or database.
#' The data must contain "ts", "antBearing", "fullID", "recvDeployName",
#' "recvDeployLat", "recvDeployLon", and optionally "gpsLat" and "gpsLon". If
#' GPS lat/lon are included, they will be used rather than recvDeployLat/Lon.
#' These data are generally contained in the `alltags` or the `alltagsGPS`
#' views. If a motus database is submitted, the `alltagsGPS` view will be used.
#'
#' @param sitename Character vector. Subset of sites to plot. If `NULL`, all
#'   unique sites are plotted.
#' @param ncol Numeric. Passed on to `ggplot2::facet_wrap()`
#' @param nrow Numeric. Passed on to `ggplot2::facet_wrap()`
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
#' # Plot all sites within file for tbl file tbl_alltags
#' plotSite(tbl_alltags)
#'
#' # Plot only detections at a specific site; Piskwamish
#' plotSite(tbl_alltags, sitename = "Piskwamish")
#' 
#' # For more custom filtering, convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
#' df_alltags <- collect(tbl_alltags)
#'
#' # Plot only detections for specified tags for data.frame df_alltags
#' plotSite(filter(df_alltags, motusTagID %in% c(16047, 16037, 16039)))
#'
#' @export

plotSite <- function(df_src, sitename = NULL, ncol = NULL, nrow = NULL, data) {
  
  if(!missing(data)) {
    warning("`data` is deprecated in favour of `df_src`)", call. = FALSE)
    df_src <- data
  }
  
  df <- check_df_src(df_src, cols = c("ts", "antBearing", "fullID", "recvDeployName", 
                                      "recvDeployLat", "recvDeployLon"),
                     view = "alltagsGPS", collect = FALSE)
  
  if(!is.null(sitename)) {
    df <- dplyr::filter(df, .data[["recvDeployName"]] %in% .env$sitename)
  }
  
  df <- df %>%  
    dplyr::collect() |>
    dplyr::mutate(hour = 3600 * round(as.numeric(.data$ts)/3600, 0))  %>% ## round times to the hour
    dplyr::select("hour", "antBearing", "fullID", "recvDeployName", "recvDeployLat", "recvDeployLon",
                  dplyr::any_of(c("gpsLat", "gpsLon"))) %>% 
    dplyr::distinct()
  
  # Add missing columns if required
  if(!all(c("gpsLat", "gpsLon") %in% names(df))) {
    df <- dplyr::mutate(df, gpsLat = NA, gpsLon = NA)
  }
  
  df <- df |>
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
    ggplot2::facet_wrap("recvDeployName", nrow = nrow, ncol = ncol) + 
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}
