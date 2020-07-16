#' General summary of detections for each tag
#'
#' Creates a summary for each tag of it's first and last detection time, first
#' and last detection site, length of time between first and last detection,
#' straight line distance between first and last detection site, rate of
#' movement, and bearing
#'
#' @param data a selected table from .motus data, eg. "alltagsGPS", or a
#'   data.frame of detection data including at a minimum variables for
#'   motusTagID, fullID, recvDeployLat, recvDeployLon, recvDeployName, ts,
#'   gpsLat, gpsLon
#' @export
#'
#' @return a data.frame with these columns:
#' \itemize{
#' \item fullID: fullID of Motus registered tag
#' \item first_ts: time of first detection of tag
#' \item last_ts: time of last detection of tag
#' \item first_site: first detection site of tag
#' \item last_site: last detection site of tag
#' \item lat.x: latitude of first deteciton site of tag
#' \item lon.x: longitude of first deteciton site of tag
#' \item lat.y: latitude of last deteciton site of tag
#' \item lon.y: longitude of last deteciton site of tag
#' \item tot_ts: length of time between first and last detection of tag (in seconds)
#' \item dist: total straight line distance between first and last detection site (in metres), see latLonDist function in sensorgnome package for details
#' \item rate: overall rate of movement (tot_ts/dist), in metres/second
#' \item bearing: bearing between first and last detection sites, see bearing function in geosphere package for more details
#' }
#'
#' @examples
#' # You can use either a selected tbl from .motus eg. "alltagsGPS", or a
#' # data.frame, instructions to convert a .motus file to all formats are below.
#' 
#' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#' 
#' # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' library(dplyr)
#' tbl.alltags <- tbl(sql.motus, "alltagsGPS") 
#' 
#' # convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' df.alltags <- tbl.alltags %>% 
#'   collect() %>% 
#'   as.data.frame()
#' 
#' # Create tag summary for all tags within detection data using tbl file
#' # tbl.alltags
#' tag_summary <- tagSum(tbl.alltags)
#' 
#' # Create site summaries for only select tags using tbl file tbl.alltags
#' tag_summary <- tagSum(filter(tbl.alltags, 
#'                              motusTagID %in% c(16047, 16037, 16039)))
#'
#' # Create site summaries for only a select species using data.frame df.alltags
#' tag_summary <- tagSum(filter(df.alltags, speciesEN == "Red Knot"))

tagSum <- function(data){
  data <- data %>% dplyr::collect() %>% as.data.frame()
  data <- dplyr::mutate(data,
                        recvLat = dplyr::if_else((is.na(.data$gpsLat)|.data$gpsLat == 0|.data$gpsLat ==999),
                                                 .data$recvDeployLat,
                                                 .data$gpsLat),
                        recvLon = dplyr::if_else((is.na(.data$gpsLon)|.data$gpsLon == 0|.data$gpsLon == 999),
                                                 .data$recvDeployLon,
                                                 .data$gpsLon),
                        recvDeployName = paste(.data$recvDeployName, 
                                               round(.data$recvLat, digits = 1), sep = "_" ),
                        recvDeployName = paste(.data$recvDeployName,
                                               round(.data$recvLon, digits = 1), sep = ", "),
                        ts = lubridate::as_datetime(.data$ts, tz = "UTC"))
  grouped <- dplyr::group_by(data, .data$fullID)
  tmp <- dplyr::summarise(grouped,
                          first_ts=min(.data$ts),
                          last_ts=max(.data$ts),
                          tot_ts = difftime(max(.data$ts), min(.data$ts), units = "secs"),
                          num_det = length(.data$ts)) ## total time in seconds
  tmp <- merge(tmp, subset(data, select = c("ts", "fullID", "recvDeployName", "recvLat", "recvLon")),
               by.x = c("first_ts", "fullID"), by.y = c("ts", "fullID"), all.x = TRUE)
  tmp <- unique(merge(tmp, subset(data, select = c("ts", "fullID", "recvDeployName", "recvLat", "recvLon")),
                      by.x = c("last_ts", "fullID"), by.y = c("ts", "fullID"), all.x = TRUE))
  tmp <- dplyr::rename(tmp, first_site = .data$recvDeployName.x, last_site = .data$recvDeployName.y)
  tmp$dist <- with(tmp, latLonDist(recvLat.x, recvLon.x, recvLat.y, recvLon.y)) ## distance in meters
  tmp$rate <- with(tmp, dist/(as.numeric(tot_ts))) ## rate of travel in m/s
  tmp$bearing <- with(tmp, geosphere::bearing(matrix(c(recvLon.x, recvLat.x), ncol=2),
                                              matrix(c(recvLon.y, recvLat.y), ncol=2))) ## bearing (see package geosphere for help)
  #  tmp$rhumbline_bearing <- with(tmp, geosphere::bearingRhumb(matrix(c(recvLon.x, recvLat.x), ncol=2),
  #                                                        matrix(c(recvLon.y, recvLat.y), ncol=2))) ## rhumbline bearing (see package geosphere for help)
  return(tmp[c("fullID", "first_ts", "last_ts", "first_site", "last_site", "recvLat.x", "recvLon.x",
               "recvLat.y", "recvLon.y", "tot_ts", "dist", "rate", "bearing", "num_det")])
}
