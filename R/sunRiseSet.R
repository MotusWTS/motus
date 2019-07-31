#' Obtain sunrise and sunset times
#'
#' Creates and adds a sunrise and sunset column to a data.frame containing latitude, longitude, 
#' and a date/time as POSIXct or numeric.
#'
#' @param data a selected table from .motus detection data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for date/time, latitude, and longitude
#' @param lat variable with latitude values, defaults to recvDeployLat
#' @param lon variable with longitude values, defaults to recvDeployLon
#' @param ts variable with time in UTC as numeric or POSIXct, defaults to ts
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @return the original dataframe provided, with the following additional columns:
#' - sunrise: sunrise time for the date and location provided by ts and lat/lon per row
#' - sunset: sunset time for the date and location provided by ts and lat/lon per row
#'
#' @examples
#' # You can use either a selected tbl from .motus eg. "alltags", or a
#' # data.frame, instructions to convert a .motus file to all formats are below.
#' 
#' # download and access data from project 176 in sql format
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
#' # Add sunrise and sunset columns to a data.frame from alltags
#' sun <- sunRiseSet(df.alltags)
#' 
#' # Get sunrise and sunset information from tbl.alltags using gps lat/lon
#' # Note this only works if there are non-NA values in gpsLat/gpsLon
#' \dontrun{sun <- sunRiseSet(tbl.alltags, lat = "gpsLat", lon = "gpsLon")}


sunRiseSet <- function(data, lat = "recvDeployLat", lon = "recvDeployLon", ts = "ts"){
  data <- data %>% dplyr::collect() %>% as.data.frame()
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  cols <- c(lat, lon, ts) ## Select columns that can't contain NA values
  loc_na <- data[!stats::complete.cases(data[cols]),] ## new dataframe with NA values in lat, lon, or ts
  loc <- data[stats::complete.cases(data[cols]),] ## new dataframe with no NA values in lat, lon, or ts
  loc$sunrise <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunrise')$time
  loc$sunset <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunset')$time
  data <- merge(loc, loc_na, all = TRUE)
  return(data)
}
