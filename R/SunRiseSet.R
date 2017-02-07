#' Obtain sunrise and sunset times
#'
#' Creates and adds a sunrise and sunset column to a dataframe containing latitude, longitude, and a POSIXct date/time
#'
#' @param data dataframe of Motus detection data, or dataframe containing latitude, longitude, and POSIXct date/time
#' @export
#' @return the original dataframe provided, with the following additional columns:
#' - sunrise: sunrise time for the date and location provided by ts and lat/lon per row
#' - sunset: sunset time for the date and location provided by ts and lat/lon per row
#' @examples
#' dat <- SunRiseSet(dat) ## adds sunrise and sunset columns to dataframe "dat"

## ts needs to be in POSIXct
SunRiseSet <- function(data){
  cols <- c("lat", "lon", "ts") ## Select columns that can't contain NA values
  loc_na <- data[!complete.cases(data[cols]),] ## new dataframe with NA values in lat, lon, or ts
  loc <- data[complete.cases(data[cols]),] ## new dataframe with no NA values in lat, lon, or ts
  loc$sunrise <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunrise')$time ## sunrise column
  loc$sunset <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunset')$time ## sunset column
  data <- merge(loc, loc_na, all = TRUE) ## merge back with rows that contain NA values
  return(data)
}
