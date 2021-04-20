#' Obtain sunrise and sunset times
#'
#' Creates and adds a sunrise and sunset column to a data.frame containing
#' latitude, longitude, and a date/time as POSIXct or numeric.
#'
#' @param data a selected table from .motus detection data, eg. "alltags", or a
#'   data.frame of detection data including at a minimum variables for
#'   date/time, latitude, and longitude
#' @param lat variable with latitude values, defaults to recvDeployLat
#' @param lon variable with longitude values, defaults to recvDeployLon
#' @param ts variable with time in UTC as numeric or POSIXct, defaults to ts
#'
#' @return the original dataframe provided, with the following additional
#'   columns:
#' - sunrise: sunrise time for the date and location provided by ts and lat/lon
#' per row
#' - sunset: sunset time for the date and location provided by ts and lat/lon
#' per row
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
#' # Extract alltags, collect (flatten to data frame), add sunrise/sunset cols:
#' sun <- sunRiseSet(sql.motus)
#' 
#' # For other views, extract them first:
#' library(dplyr)
#' tbl.alltagsGPS <- tbl(sql.motus, "alltagsGPS") 
#' 
#' # Add sunrise/sunset (after flattening to data frame)
#' sun <- sunRiseSet(tbl.alltagsGPS)
#' 
#' # Or, submit a flattened data frame:
#' df.alltags <- collect(tbl.alltags)
#' 
#' # Add sunrise/sunset
#' sun <- sunRiseSet(df.alltags)
#' 
#' # Get sunrise and sunset information from tbl.alltags using gps lat/lon
#' # Note this only works if there are non-NA values in gpsLat/gpsLon
#' \dontrun{sun <- sunRiseSet(tbl.alltagsGPS, lat = "gpsLat", lon = "gpsLon")}
#' 
#' @export

sunRiseSet <- function(data, lat = "recvDeployLat", lon = "recvDeployLon", ts = "ts"){
  if("src_SQLiteConnection" %in% class(data)) {
    message("'data' is a complete motus data base, using 'alltags' view")
    data <- dplyr::tbl(data, "alltags")
  }
  if(!is.data.frame(data) && !dplyr::is.tbl(data)) {
    stop("'data' must be a data frame, table/view (e.g., alltags), ",
         "or motus SQLite database (see ?sunRiseSet for examples)", call. = FALSE)
  }
     
  if(!requireNamespace("lutz", quietly = TRUE)) {
    stop("The package 'lutz' is required to calculate sunrise/sunset times.\n", 
         "You can install it with 'install.packages(\"lutz\")'", call. = FALSE)
  }
    
  requiredCols(data, req = c(lat, lon, ts))

  data <- dplyr::collect(data) %>%
    dplyr::mutate(ts := lubridate::as_datetime(.data[[ts]], tz = "UTC"))

  data_date <- data %>% 
    dplyr::mutate(tz = lutz::tz_lookup_coords(.data[[lat]], .data[[lon]], warn = FALSE)) %>%
    tidyr::nest(data = c(-"tz")) %>%
    dplyr::mutate(date = purrr::map2(.data$data, .data$tz, ~get_date(.x[[ts]], .y))) %>%
    tidyr::unnest(c(date, data)) %>%
    dplyr::select(-"tz")

  
  if(sum(!is.na(data_date$date)) == 0)  stop("No data with non-missing coordinates in '", 
                                             lat, "' and '", lon, "'", call. = FALSE)
  
  sun <- data_date %>%
    dplyr::select(.data[[lon]], .data[[lat]], .data$date) %>%
    dplyr::filter(!is.na(.data$date), !is.na(.data[[lon]]), !is.na(.data[[lat]])) %>%
    dplyr::distinct() %>%
    dplyr::mutate(sunrise = sunriset(.data[[lon]], .data[[lat]], .data$date, 
                                     direction = "sunrise"),
                  sunset = sunriset(.data[[lon]], .data[[lat]], .data$date,
                                    direction = "sunset")) %>%
    dplyr::select("date", .data[[lon]], .data[[lat]], "sunrise", "sunset")
                  
  data_date %>%
    dplyr::left_join(sun, by = c(lat, lon, "date")) %>%
    dplyr::select(-"date")
}

sunriset <- function(lon, lat, time, direction) {
  maptools::sunriset(crds = as.matrix(cbind(lon, lat)), 
                     dateTime = time,  
                     POSIXct.out = TRUE, 
                     direction = direction)$time
}

get_date <- function(x, tz) {
  if(!is.na(tz)) {
    d <- lubridate::as_date(lubridate::with_tz(x, tz = tz)) %>%
      lubridate::force_tz("UTC") 
  } else d <- as.Date(NA)
  d
  # sunriset only uses the input TZ to determine output TZ, 
  # not for actual sunrise/set calculations
}
  
