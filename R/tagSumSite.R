#' Summarize detections of all tags by site
#'
#' Creates a summary for each tag of it's first and last detection time at each
#' site, length of time between first and last detection of each site, and total
#' number of detections at each site.
#'
#' @param data a selected table from .motus data, eg. "alltagsGPS", or a
#'   data.frame of detection data including at a minimum variables for
#'   motusTagID, fullID, recvDeployName, ts, recvDeployLat, recvDeployLon,
#'   gpsLat, gpsLon
#' @param units units to display time difference, defaults to "hours", options
#'   include "secs", "mins", "hours", "days", "weeks"
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
#' tbl_alltags <- tbl(sql_motus, "alltagsGPS") 
#' 
#' # convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
#' df_alltags <- tbl_alltags  %>% 
#'   collect() %>% 
#'   as.data.frame() 
#' 
#' # Create tag summaries for all tags within detection data with time in
#' # minutes with tbl file tbl_alltags
#' tag_site_summary <- tagSumSite(tbl_alltags, units = "mins")
#' 
#' # Create tag summaries for only select tags with time in default hours with
#' # data.frame df_alltags
#' tag_site_summary <- tagSumSite(filter(df_alltags, 
#'                                       motusTagID %in% c(16047, 16037, 16039)))
#'
#' # Create tag summaries for only a select species with data.frame df_alltags
#' tag_site_summary <- tagSumSite(filter(df_alltags, speciesEN == "Red Knot"))

tagSumSite <- function(data, units = "hours"){
  data <- dplyr::select(data, "motusTagID", "fullID", "recvDeployName", "recvDeployLat", 
                        "recvDeployLon", "gpsLat", "gpsLon", "ts") %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    as.data.frame()
  data <- dplyr::mutate(
    data,
    recvLat = dplyr::if_else((is.na(.data$gpsLat)|.data$gpsLat == 0|.data$gpsLat ==999),
                             .data$recvDeployLat,
                             .data$gpsLat),
    recvLon = dplyr::if_else((is.na(.data$gpsLon)|.data$gpsLon == 0|.data$gpsLon == 999),
                             .data$recvDeployLon,
                             .data$gpsLon),
    recvDeployName = paste(.data$recvDeployName, 
                           round(.data$recvLat, digits = 1), sep = "\n" ),
    recvDeployName = paste(.data$recvDeployName,
                           round(.data$recvLon, digits = 1), sep = ", "),
    ts = lubridate::as_datetime(.data$ts, tz = "UTC"))
  grouped <- dplyr::group_by(data, .data$fullID, .data$recvDeployName)
  data <- dplyr::summarise(grouped,
                           first_ts=min(.data$ts),
                           last_ts=max(.data$ts),
                           tot_ts = difftime(max(.data$ts), min(.data$ts), units = units),
                           num_det = length(.data$ts))
  
  as.data.frame(data)
}
