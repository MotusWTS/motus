#' General summary of detections for each tag
#'
#' Creates a summary for each tag of it's first and last detection time (`ts`),
#' first and last detection site, length of time between first and last
#' detection, straight line distance between first and last detection site, rate
#' of movement, and bearing. Lat/lons are taken from `gpsLat`/`gpsLon`, or if
#' missing, from `recvDeployLat`/`recvDeployLon`. Bearing is calculated using
#' the `geosphere::bearing()` function.
#' 
#' @inheritParams args
#' 
#' @export
#'
#' @return A flat data frame with the following for each tag:
#' 
#' - `fullID` - `fullID` of Motus registered tag
#' - `first_ts` - Time (`ts`) of first detection
#' - `last_ts` - Time (`ts`) of last detection
#' - `first_site` - First detection site (`recvDeployName`)
#' - `last_site` - Last detection site (`recvDeployName`)
#' - `recvLat.x` - Latitude of first detection site (`gpsLat` or `recvDeployLat`)
#' - `recvLon.x` - Longitude of first detection site (`gpsLon` or `recvDeployLon`)
#' - `recvLat.y` - Latitude of last detection site (`gpsLat` or `recvDeployLat`)
#' - `recvLon.y` - Longitude of last detection site (`gpsLon` or `recvDeployLon`)
#' - `tot_ts` - Time between first and last detection (in seconds)
#' - `dist` - Straight line distance between first and last detection site (in metres)
#' - `rate` - Overall rate of movement (`tot_ts`/`dist`), in metres/second
#' - `bearing` - Bearing between first and last detection sites
#' - `num_det` - Number of detections summarized
#'
#' @examples
#' 
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#' 
#' # Summarize tags
#' tag_summary <- tagSum(sql_motus)
#' 
#' # For specific SQLite table/view (needs gpsLat/gpsLon) --------------
#' library(dplyr)
#' tbl_alltagsGPS <- tbl(sql_motus, "alltagsGPS") 
#' tag_summary <- tagSum(tbl_alltagsGPS)
#' 
#' # For a flattened data frame ----------------------------------------
#' df_alltagsGPS <- collect(tbl_alltagsGPS)
#' tag_summary <- tagSum(df_alltagsGPS)
#' 
#' # Can be filtered, e.g., for only a few tags
#' tag_summary <- tagSum(filter(tbl_alltagsGPS, motusTagID %in% c(16047, 16037, 16039)))

tagSum <- function(df_src, data){

  # TODO: When sp evolution messages resolved, remove 
  #      `suppressPackageStartupMessages()` from geosphere functions
  
  # Deprecate data - 2023-09
  if(!missing(data)) {
    warning("Argument `data` is deprecated in favour of `df_src`", call. = FALSE)
    df_src <- data
  }
  
  # Checks
  df <- check_df_src(
    df_src, 
    cols = c("fullID", "recvDeployName", "recvDeployLat", "recvDeployLon", 
             "gpsLat", "gpsLon", "ts"), 
    view = "alltagsGPS")
  
  df <- df %>%
    dplyr::mutate(
      recvLat = dplyr::if_else(
        is.na(.data[["gpsLat"]]) | .data[["gpsLat"]] == 0 | .data[["gpsLat"]] == 999,
        .data[["recvDeployLat"]], .data[["gpsLat"]]),
      recvLon = dplyr::if_else(
        is.na(.data[["gpsLon"]]) | .data[["gpsLon"]] == 0 | .data[["gpsLon"]] == 999,
        .data[["recvDeployLon"]], .data[["gpsLon"]]),
      recvDeployName = paste(.data[["recvDeployName"]], 
                             round(.data[["recvLat"]], digits = 1), sep = "_" ),
      recvDeployName = paste(.data[["recvDeployName"]],
                             round(.data[["recvLon"]], digits = 1), sep = ", "),
      ts = lubridate::as_datetime(.data[["ts"]], tz = "UTC"))
  
  tmp <- df %>%
    dplyr::group_by(.data[["fullID"]]) %>%
    dplyr::summarise(
      first_ts = min(.data[["ts"]]),
      last_ts = max(.data[["ts"]]),
      # Total time in seconds
      tot_ts = as.numeric(difftime(max(.data[["ts"]]), min(.data[["ts"]]), units = "secs")),
      # Number of detections
      num_det = length(.data$ts))
  
  # Add in first detection
  tmp <- dplyr::left_join(
    tmp, dplyr::select(df, "ts", "fullID", "recvDeployName", "recvLat", "recvLon"),
    by = c("first_ts" = "ts", "fullID"))
  
  # Add in last detection
  tmp <- dplyr::left_join(
    tmp, dplyr::select(df, "ts", "fullID", "recvDeployName", "recvLat", "recvLon"),
    by = c("last_ts" = "ts", "fullID"))
  
  # Clean up and calculations
  tmp <- dplyr::distinct(tmp) %>%
    dplyr::rename("first_site" = "recvDeployName.x", 
                  "last_site" = "recvDeployName.y") %>%
    dplyr::mutate(
      # Distance in metres
      dist = latLonDist(.data[["recvLat.x"]], .data[["recvLon.x"]],
                        .data[["recvLat.y"]], .data[["recvLon.y"]]),
      # Rate of travel in m/s
      rate = .data[["dist"]]/(as.numeric(.data[["tot_ts"]])),
      # Bearing (see package geosphere for help)
      bearing = 
        suppressPackageStartupMessages( # TODO: Remove when sp evolution complete
          geosphere::bearing(
            matrix(c(.data[["recvLon.x"]], .data[["recvLat.x"]]), ncol = 2),
            matrix(c(.data[["recvLon.y"]], .data[["recvLat.y"]]), ncol = 2))))
  
  tmp %>%
    dplyr::select("fullID", 
                  "first_ts", "last_ts", 
                  "first_site", "last_site", 
                  "recvLat.x", "recvLon.x",
                  "recvLat.y", "recvLon.y", 
                  "tot_ts", "dist", "rate", "bearing", "num_det") %>%
    dplyr::arrange(.data[["fullID"]], .data[["first_ts"]])
}
