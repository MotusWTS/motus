#' Obtain time to and from sunrise/sunset for a dataframe containing POSIXct times
#'
#' Creates and adds columns for time to, and time from sunrise/sunset based on a column of POSIXct dates/times
#' dataframe must contain latitude, longitude, and a POSIXct date/time.
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables ts, lat, lon
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#'
#' @export
#'
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @return the original dataframe provided, with the following additional columns:
#' \itemize{
#' \item sunrise: sunrise time for the date and location provided by ts and lat/lon per row
#' \item sunset: sunset time for the date and location provided by ts and lat/lon per row
#' \item ts_to_set: time to next sunset after "ts", units default to "hours"
#' \item ts_since_set: time to previous sunset since "ts", units default to "hours"
#' \item ts_to_rise: time to next sunrise after "ts", units default to "hours"
#' \item ts_since_rise: time to previous sunrise since "ts", units default to "hours"
#' }
#'
#' @examples
#' You can use either the tbl or the flat format for the siteTrans function, instructions to convert
#' a .motus file to both formats is below.
#' To access any tbl from .motus data saved on your computer:
#' file.name <- "data/project-sample.motus" ## replace with the full location of the sample dataset or your own project-XX.motus file
#' tmp <- dplyr::src_sqlite(file.name)
#' alltags <- tbl(motusSqlFile, "alltags")
#' 
#' To convert tbl to flat format:
#' alltags <- alltags %>% collect %>% as.data.frame
#' 
#' get sunrise and sunset information with units in minutes
#' sunrise <- timeToSunriset(alltags, units = "mins")

timeToSunriset <- function(data, units = "hours"){
  data <- data %>% collect %>% as.data.frame
  data$ts <- as_datetime(data$ts, tz = "UTC")
  cols <- c("lat", "lon", "ts") ## Select columns that can't contain NA values
  loc_na <- data[!complete.cases(data[cols]),] ## new dataframe with NA values in lat, lon, or ts
  loc <- data[complete.cases(data[cols]),] ## new dataframe with no NA values in lat, lon, or ts
  loc$sunrise <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunrise')$time
  loc$sunset <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunset')$time
  ## to get time difference, must take into account whether you are going to/from sunrise/sunset from the
  ## previous or next day, this depends on when the detection was in relation to sunrise/sunset times for that day.
  loc$ts_to_set <- ifelse(loc$ts < loc$sunset, difftime(loc$sunset, loc$ts, units = units),
                          difftime(maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)), (loc$ts + 86400), POSIXct.out=T, direction='sunset')$time, loc$ts, units = units))
  loc$ts_since_set <- ifelse(loc$ts > loc$sunset, difftime(loc$ts, loc$sunset, units = units),
                             difftime(loc$ts, maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)), (loc$ts - 86400), POSIXct.out=T, direction='sunset')$time, units = units))
  loc$ts_to_rise <- ifelse(loc$ts < loc$sunrise, difftime(loc$sunrise, loc$ts, units = units),
                           difftime(maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)), (loc$ts + 86400), POSIXct.out=T, direction='sunrise')$time, loc$ts, units = units))
  loc$ts_since_rise <- ifelse(loc$ts > loc$sunrise, difftime(loc$ts, loc$sunrise, units = units),
                              difftime(loc$ts, maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)), (loc$ts - 86400), POSIXct.out=T, direction='sunrise')$time, units = units))
  data <- merge(loc, loc_na, all = TRUE)
  return(data)
}
