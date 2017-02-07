#' Summarize transitions between sites for each tag
#'
#' Creates a dataframe of transitions between sites; detections are ordered by detection time, then "transitions"
#' are identified as the period between the final detection at site x (possible "departure"), and the first detection
#' (possible "arrival") at site y (ordered chronologically). Each row contains the last detection time and lat/lon
#' of site x, first deteciton time and lat/lon of site y, distance between the site pair, time between detections,
#' rate of movement between detections, bearing and rhumbline bearing between site pair.
#'
#' @param data dataframe of Motus detection data containing at a minimum fullID, ts, lat, lon
#'
#' @return a data.frame with these columns:
#' \itemize{
#' \item fullID: fullID of Motus registered tag
#' \item ts.x: time of last detection of tag at site.x ("departure" time)
#' \item lat.x: latitude of site.x
#' \item lon.x: longitude of site.x
#' \item site.x: first site in transition pair (the "departure" site)
#' \item ts.y: time of first detection of tag at site.y ("arrival" time)
#' \item lat.y: latitude of site.y
#' \item lon.y: longitude of site.y
#' \item site.y: second site in transition pair (the "departure" site)
#' \item tot_ts: length of time between ts.x and ts.y (in seconds)
#' \item dist: total straight line distance between site.x and site.y (in metres), see latLonDist function in sensorgnome package for details
#' \item rate: overall rate of movement (tot_ts/dist), in metres/second
#' \item bearing: bearing between first and last detection sites, see bearing function in geosphere package for more details
#' \item rhumbline_bearing: rhumbline bearing between first and last detection sites, see bearingRhumb function in geosphere package for more detail
#'}
#'
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#'
#' @examples
#' transitions <- siteTrans(dat)

## at this point it keeps both detections for simultaneous detections (see tag 378, sites Shelburne and BennettMeadow)
## also get a ton of transitions between close detections (see tag 181 between sites FI and Bull)
## site.fun and consec.fun adapted from "between.locs.R" script written by Phil

siteTrans <- function(data){
  data <- subset(data, select = c(ts, fullID, lat, lon, site)) ## get only relevant columns
  data <- data %>% dplyr::group_by(fullID) %>% do(consec.fun(.))
  data <- data %>% dplyr::group_by(fullID) %>% do(site.fun(.))
  data$tot_ts = difftime(data$ts.y, data$ts.x, units = "secs")
  data$dist <- with(data, sensorgnome::latLonDist(lat.x, lon.x, lat.y, lon.y)) ## distance in meters
  data$rate <- with(data, dist/(as.numeric(tot_ts))) ## rate of travel in m/s
  data$bearing <- with(data, geosphere::bearing(matrix(c(lon.x, lat.x), ncol=2),
                                   matrix(c(lon.y, lat.y), ncol=2))) ## bearing (see package geosphere for help)
  data$rhumbline_bearing <- with(data, geosphere::bearingRhumb(matrix(c(lon.x, lat.x), ncol=2),
                                                  matrix(c(lon.y, lat.y), ncol=2))) ## rhumbline bearing (see package geosphere for help)
  return(data)
}
