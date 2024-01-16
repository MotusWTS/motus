#' Obtain time to and from sunrise/sunset
#'
#' Create and add columns for time to and time since sunrise/sunset to tag data.
#' Can take a motus database table, but will always return a collected data
#' frame. Requires data containing at least latitude, longitude, and time.
#' 
#' Uses `sunRiseSet()` to perform sunrise/sunset calculates, see `?sunRiseSet`
#' for details regarding how local dates are assessed from UTC timestamps.
#'
#' @param lat Character. Name of column with latitude values, defaults to
#'   `recvDeployLat`
#' @param lon Character. Name of column with longitude values, defaults to
#'   `recvDeployLon`
#' @param ts Character. Name of column with time as numeric or POSIXct, defaults
#'   to `ts`
#' @param units Character. Units to display time difference, defaults to
#'   "hours", options include "secs", "mins", "hours", "days", "weeks".
#'   
#' @inheritParams args
#' 
#' @export
#'
#' @return Original data (as a flat data frame), with the following additional
#'   columns:
#'   
#' - `sunrise` - Time of sunrise in **UTC** for that row's date and location
#' - `sunset` - Time of sunset in **UTC** for that row's date and location
#' - `ts_to_set` - Time to next sunset, in `units`
#' - `ts_since_set` - Time to previous sunset, in `units`
#' - `ts_to_rise` - Time to next sunrise after, in `units`
#' - `ts_since_rise` - Time to previous sunrise, in `units`
#'
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#' 
#' # Get sunrise and sunset information for alltags view with units in minutes
#' sunrise <- timeToSunriset(sql_motus, units = "mins")

timeToSunriset <- function(df_src, lat = "recvDeployLat", lon = "recvDeployLon",
                           ts = "ts", units = "hours", data){

  # Deprecate data - 2023-09
  if(!missing(data)) {
    warning("Argument `data` is deprecated in favour of `df_src`", call. = FALSE)
    df_src <- data
  }
  
  # Checks
  df <- check_df_src(df_src, cols = c(lat, lon, ts))
  
  # Calculate sunrise/set times for day of, before and after for all dates
  df_ts <- df %>%
    dplyr::select(dplyr::all_of(c(lat, lon, ts))) %>%
    dplyr::mutate(.date = lubridate::as_datetime(.data[[ts]], tz = "UTC"))
  
  sun <- dplyr::select(df_ts, dplyr::all_of(c(lat, lon, ".date"))) %>%
    dplyr::distinct()
  
  sun_day <- sunRiseSet(sun, lat = lat, lon = lon, ts = ".date")
  
  sun_before <- sunRiseSet(dplyr::mutate(sun, `.date` = .data[[".date"]] - lubridate::days(1)),
                           lat = lat, lon = lon, ts = ".date") %>%
    dplyr::select("sunrise_before" = "sunrise", "sunset_before" = "sunset")
  sun_after <- sunRiseSet(dplyr::mutate(sun, `.date` = .data[[".date"]] + lubridate::days(1)),
                         lat = lat, lon = lon, ts = ".date") %>%
    dplyr::select("sunrise_after" = "sunrise", "sunset_after" = "sunset")

  # Join back in with timestamps and calculate difftimes
  sun <- dplyr::bind_cols(sun[".date"], sun_day, sun_before, sun_after) %>%
    dplyr::left_join(df_ts, by = c(lat, lon, ".date")) %>%
    tidyr::drop_na()

  sun$ts_to_rise <- sun$sunrise - sun$`.date`
  sun$ts_to_rise[sun$ts_to_rise < 0] <- sun$sunrise_after[sun$ts_to_rise < 0] - sun$`.date`[sun$ts_to_rise < 0]
  
  sun$ts_to_set <- sun$sunset - sun$`.date`
  sun$ts_to_set[sun$ts_to_set < 0] <- sun$sunset_after[sun$ts_to_set < 0] - sun$`.date`[sun$ts_to_set < 0]
  
  sun$ts_since_rise <- sun$`.date` - sun$sunrise
  sun$ts_since_rise[sun$ts_since_rise < 0] <- sun$`.date`[sun$ts_since_rise < 0] - sun$sunrise_before[sun$ts_since_rise < 0]
  
  sun$ts_since_set <- sun$`.date` - sun$sunset
  sun$ts_since_set[sun$ts_since_set < 0] <- sun$`.date`[sun$ts_since_set < 0] - sun$sunset_before[sun$ts_since_set < 0]
  
  # Set units and return as numeric
  sun$ts_to_rise <- as.double(sun$ts_to_rise, units = units)
  sun$ts_to_set <- as.double(sun$ts_to_set, units = units)
  sun$ts_since_rise <- as.double(sun$ts_since_rise, units = units)
  sun$ts_since_set <- as.double(sun$ts_since_set, units = units)
  
  sun <- dplyr::select(sun, dplyr::all_of(c(lat, lon, ts)), 
                       "sunrise", "sunset", 
                       "ts_to_rise", "ts_to_set", "ts_since_rise", "ts_since_set")
  
  dplyr::left_join(df, sun, by = c(lat, lon, ts))
}
