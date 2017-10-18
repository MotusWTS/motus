#' Obtain sunrise and sunset times
#'
#' Creates and adds a sunrise and sunset column to a data.frame containing latitude, longitude, and a POSIXct date/time
#'
#' @param data data.frame of Motus detection data, or data.frame containing latitude, longitude, and POSIXct date/time
#' @param lat column containing latitude 
#' @param lon column containing longitude
#' @param ts.name column containing ts in POSIXct format
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @return the original dataframe provided, with the following additional columns:
#' - sunrise: sunrise time for the date and location provided by ts and lat/lon per row
#' - sunset: sunset time for the date and location provided by ts and lat/lon per row
#' @examples
#' convert a .motus file to a data.frame
#' tmp <- tbl(motusSqlFile, "alltags") ## access the "alltags" tbl from the sql
#' tmp <- tmp %>% distinct %>% collect %>% as.data.frame ## convert tbl to data.frame for typical "flat" format
#' tmp$ts <- as_datetime(data$ts, tz = "UTC") ## convert ts to POSIXct; requires package "lubridate"
#' 
#' Add sunrise/sunset columns to data.frame "tmp"
#' tmp <- SunRiseSet(tmp)

SunRiseSet <- function(data, lat.name = "lat", lon.name = "lon", ts.name = "ts"){
  if(class(data$ts) !="POSIXct") stop('ts must be in class POSIXct') 
#  cols <- c("lat", "lon", "ts") ## Select columns that can't contain NA values
#  loc_na1 <- data[!complete.cases(data[cols]),] ## new dataframe with NA values in lat, lon, or ts
  test$lat.name[is.na(test$lat.name)] <- 0
  loc <- filter_(data, paste(lat.name, "!=",0), paste(lon.name, "!=",0))
  cols_to_filter = c("lat.name", "ant.name")
  lat.na <- filter_(data, paste(lat.name, "!=",0) & paste(ant.name, "!=",0))
  lon.na <- filter_(data, paste(ant.name, "!=",0))
  na <- suppressMessages(full_join(lat.na, lon.na)) ## join grouped data with data
  
  lat.full <- filter_(data, paste(lat.name, "!=",0))
  lon.full <- filter_(data, paste(ant.name, "!=",0))
  full <- suppressMessages(full_join(lat.full, lon.full)) ## join grouped data with data
  
  
  loc1 <- filter_(data, interp(~var == 0, var = as.name(lat.name)) | interp(~var == 0, var = as.name(lat.name)))
  loc2 <- filter_(interp(~var == 0, var = as.name(ant.name)))
  loc1 <- subset(data, lat ==0 | lon == 0 | ant == 0)
  
  loc2 <- filter(data, is.na(lat))
  
#  loc <- data[complete.cases(data[cols]),] ## new dataframe with no NA values in lat, lon, or ts
  loc_na <- filter_(data, !is.na(paste(lat.name, "!=",0)), !is.na(paste(lon.name, "!=",0)), !is.na(paste(ts.name, "!=",0))) ## new dataframe with no NA values in lat, lon, or ts
  loc$sunrise <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunrise')$time ## sunrise column
  loc$sunset <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunset')$time ## sunset column
  data <- suppressMessages(full_join(loc, loc_na)) ## merge back with rows that contain NA values
  return(data)
}
