#' Obtain sunrise and sunset times
#'
#' Creates and adds a sunrise and sunset column to a data.frame containing latitude, longitude, and a POSIXct date/time
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables ts, lat, lon
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @return the original dataframe provided, with the following additional columns:
#' - sunrise: sunrise time for the date and location provided by ts and lat/lon per row
#' - sunset: sunset time for the date and location provided by ts and lat/lon per row
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
#' Add sunrise/sunset columns to a data.frame from alltags
#' sun <- SunRiseSet(alltags, units = "mins)

SunRiseSet <- function(data){
  data <- data %>% collect %>% as.data.frame
  data$ts <- as_datetime(data$ts, tz = "UTC")
  cols <- c("lat", "lon", "ts") ## Select columns that can't contain NA values
  loc_na <- data[!complete.cases(data[cols]),] ## new dataframe with NA values in lat, lon, or ts
  loc <- data[complete.cases(data[cols]),] ## new dataframe with no NA values in lat, lon, or ts
  loc$sunrise <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunrise')$time
  loc$sunset <- maptools::sunriset(as.matrix(dplyr::select(loc,lon,lat)),loc$ts, POSIXct.out=T, direction='sunset')$time
  data <- merge(loc, loc_na, all = TRUE)
  return(data)
}
