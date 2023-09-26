#' Obtain sunrise and sunset times
#'
#' Create and add sunrise and sunset columns to tag data. Can take a motus
#' database table, but will always return a collected data frame. Requires data
#' containing at least latitude, longitude, and time. 
#' 
#' Note that this will always return the sunrise and sunset of the *local* date.
#' For example, 2023-01-01 04:00:00 in Central North American time is 2023-01-01
#' in UTC, but 2023-01-01 20:00:00 is actually the following date in UTC.
#' Because Motus timestamps are UTC, times are first converted to their local time
#' zone time using the lat/lon coordinates before extracting the date. Thus:
#' 
#' - A UTC timestamp of 1672624800 for Winnipeg, Canada
#'   is 2023-01-02 02:00:00 UTC and 2023-01-01 20:00:00 local time
#' - Therefore `sunRiseSet()` calculates the sunrise/sunset times for 2023-01-01 
#'   (not for 2023-01-02)
#' - These sunrise/sunset times are returned in UTC: 2023-01-01 14:27:50 UTC and
#'   2023-01-01 22:38:30 UTC
#' - Note that the UTC timestamp 2023-01-02 02:00:00 is later than the sunset 
#'   time of 2023-01-01 22:38:30 UTC.
#'   This makes sense, as we know that the timestamp is ~8pm local time, 
#'   well after sunset in the winter for that date.
#' 
#' @inheritParams args
#'
#' @return Original data (as a flat data frame), with the following additional
#'   columns:
#'   
#' - `sunrise` - Time of sunrise in **UTC** for that row's date and location
#' - `sunset` - Time of sunset in **UTC** for that row's date and location
#'
#' @examples
#' 
#' # For SQLite Data base-----------------------------------------------
#' 
#' # Download sample project 176 in SQL (user and password are both "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#' 
#' # Add sunrise/sunset
#' sun <- sunRiseSet(sql_motus)
#' 
#' # For specific SQLite table/view ------------------------------------
#' library(dplyr)
#' tbl_alltagsGPS <- tbl(sql_motus, "alltagsGPS") 
#' sun <- sunRiseSet(tbl_alltagsGPS)
#' 
#' # For a flattened data frame ----------------------------------------
#' df_alltagsGPS <- collect(tbl_alltagsGPS)
#' sun <- sunRiseSet(df_alltagsGPS)
#' 
#' # Using alternate lat/lons ------------------------------------------
#' # Get sunrise and sunset information from tbl_alltags using gps lat/lon
#' # Note this will only work if there are non-NA values in gpsLat/gpsLon
#' \dontrun{sun <- sunRiseSet(tbl_alltagsGPS, lat = "gpsLat", lon = "gpsLon")}
#' 
#' @export

sunRiseSet <- function(df_src, lat = "recvDeployLat", lon = "recvDeployLon", 
                       ts = "ts", data){

  # Deprecate data - 2023-09
  if(!missing(data)) {
    warning("Argument `data` is deprecated in favour of `df_src`", call. = FALSE)
    df_src <- data
  }
  
  # Checks
  df <- check_df_src(df_src, cols = c(lat, lon, ts))
  
  if(all(is.na(df[[lat]])) | all(is.na(df[[lon]]))) {
    stop("No data with non-missing coordinates in '", lat, "' and '", lon, "'", 
         call. = FALSE)
  }
  
  # Convert ts to time
  df <- dplyr::mutate(df, .time_utc = lubridate::as_datetime(.data[[ts]], tz = "UTC"))

  # Get timezone of location 
  tz <- df %>%
    dplyr::select(!!lat, !!lon) %>%
    dplyr::distinct() %>%
    dplyr::filter(!is.na(.data[[lat]]) & !is.na(.data[[lon]])) %>%
    dplyr::mutate(.tz = lutz::tz_lookup_coords(.data[[lat]], .data[[lon]], warn = FALSE)) %>%
    tidyr::nest(data = c(-".tz")) %>%
    dplyr::mutate(.tz = purrr::map_dbl(
      .data[[".tz"]],
      ~lutz::tz_offset("2021-01-01", .)$utc_offset_h)) %>%
    tidyr::unnest("data")
  
  # Calculate local date based on timezone
  # i.e. Jan 1st 8pm Winnipeg is Jan 2nd 2am in UTC, local date is Jan 1st
  df <- df %>%
    dplyr::left_join(tz, by = c(lat, lon)) %>%
    dplyr::mutate(
      .date = .data[[".time_utc"]] + lubridate::hours(.data[[".tz"]]),
      .date = lubridate::floor_date(.data[[".date"]], unit = "day"),
      .date = lubridate::as_date(.data[[".date"]]))
  
  # Get the sunrise/set times in UTC but for the correct date
  sun <- df %>%
    dplyr::select(.data[[lon]], .data[[lat]], .data[[".date"]]) %>%
    dplyr::filter(!is.na(.data[[".date"]]), !is.na(.data[[lon]]), !is.na(.data[[lat]])) %>%
    dplyr::distinct() %>%
    dplyr::rename("lat" = .data[[lat]], "lon" = .data[[lon]], "date" = ".date") %>%
    suncalc::getSunlightTimes(data = ., keep = c("sunrise", "sunset"), tz = "UTC")
  
  df %>%
    dplyr::left_join(
      sun, by = stats::setNames(c("lat", "lon", "date"),
                                c(lat, lon, ".date"))) %>%
    dplyr::select(-".time_utc", -".date", -".tz")
}
