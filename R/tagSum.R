#' General summary of detections for each tag
#'
#' Creates a summary for each tag of it's first and last detection time, first and last detection site,
#' length of time between first and last detection,  straight line distance between first and last detection site,
#' rate of movement, bearing, and rhumbline bearing
#'
#' @param data dataframe of Motus detection data
#' @export
#' @return a data.frame with these columns:
#' \itemize{
#' \item fullID: fullID of Motus registered tag
#' \item first_ts: time of first detection of tag
#' \item last_ts: time of last detection of tag
#' \item first_site: first detection site of tag
#' \item last_site: last deteciton site of tag
#' \item lat.x: latitude of first deteciton site of tag
#' \item lon.x: longitude of first deteciton site of tag
#' \item lat.y: latitude of last deteciton site of tag
#' \item lon.y: longitude of last deteciton site of tag
#' \item tot_ts: length of time between first and last detection of tag (in seconds)
#' \item dist: total straight line distance between first and last detection site (in metres), see latLonDist function in sensorgnome package for details
#' \item rate: overall rate of movement (tot_ts/dist), in metres/second
#' \item bearing: bearing between first and last detection sites, see bearing function in geosphere package for more details
#' \item rhumbline_bearing: rhumbline bearing between first and last detection sites, see bearingRhumb function in geosphere package for more detail
#' }
#'
#' @examples
#' tag_summary <- tagSum(dat)

tagSum <- function(data){
  grouped <- dplyr::group_by(data, fullID)
  tmp <- dplyr::summarise(grouped,
                    first_ts=min(ts),
                    last_ts=max(ts),
                    tot_ts = difftime(max(ts), min(ts), units = "secs"),
                    num_det = length(ts)) ## total time in seconds
  tmp <- merge(tmp, subset(data, select = c(ts, fullID, site, lat, lon)),
               by.x = c("first_ts", "fullID"), by.y = c("ts", "fullID"), all.x = TRUE)
  tmp <- unique(merge(tmp, subset(data, select = c(ts, fullID, site, lat, lon)),
               by.x = c("last_ts", "fullID"), by.y = c("ts", "fullID"), all.x = TRUE))
  tmp <- dplyr::rename(tmp, first_site = site.x, last_site = site.y)
  tmp$dist <- with(tmp, sensorgnome::latLonDist(lat.x, lon.x, lat.y, lon.y)) ## distance in meters
  tmp$rate <- with(tmp, dist/(as.numeric(tot_ts))) ## rate of travel in m/s
  tmp$bearing <- with(tmp, geosphere::bearing(matrix(c(lon.x, lat.x), ncol=2),
                                                 matrix(c(lon.y, lat.y), ncol=2))) ## bearing (see package geosphere for help)
  tmp$rhumbline_bearing <- with(tmp, geosphere::bearingRhumb(matrix(c(lon.x, lat.x), ncol=2),
                                                        matrix(c(lon.y, lat.y), ncol=2))) ## rhumbline bearing (see package geosphere for help)
  return(tmp[c("fullID", "first_ts", "last_ts", "first_site", "last_site", "lat.x", "lon.x", "lat.y", "lon.y",
               "tot_ts", "dist", "rate", "bearing", "rhumbline_bearing", "num_det")])
}
