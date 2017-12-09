#' Summarize transitions between sites for each tag
#'
#' Creates a dataframe of transitions between sites; detections are ordered by detection time, then "transitions"
#' are identified as the period between the final detection at site x (possible "departure"), and the first detection
#' (possible "arrival") at site y (ordered chronologically). Each row contains the last detection time and lat/lon
#' of site x, first detection time and lat/lon of site y, distance between the site pair, time between detections,
#' rate of movement between detections, and bearing between site pairs.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for ts, motusTagID, tagDeployID, recvDeployLat, recvDeployLon, recvDepName
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
#'}
#'
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags, or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' View all site transitions for all detection data from tbl file tbl.alltags
#' transitions <- siteTrans(tbl.alltags)
#' 
#' View site transitions for only tag 16037 from data.frame df.alltags
#' transitions <- siteTrans(filter(df.alltags, motusTagID == 16037))

siteTrans <- function(data){
   tmp <- if(class(data) == "data.frame"){
    tmp = data
   } else {
      tmp = data %>% collect %>% as.data.frame
      }
  data <- subset(tmp, select = c(ts, motusTagID, tagDeployID, recvDeployLat, recvDeployLon, recvDepName)) ## get only relevant columns
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  data <- data %>% dplyr::group_by(motusTagID, tagDeployID) %>% do(consec.fun(.))
  data <- data %>% dplyr::group_by(motusTagID, tagDeployID) %>% do(site.fun(.))
  data$tot_ts = difftime(data$ts.y, data$ts.x, units = "secs")
  data$dist <- with(data, latLonDist(recvDeployLat.x, recvDeployLat.x, recvDeployLat.y, recvDeployLon.y)) ## distance in meters
  data$rate <- with(data, dist/(as.numeric(tot_ts))) ## rate of travel in m/s
  data$bearing <- with(data, geosphere::bearing(matrix(c(recvDeployLon.x, recvDeployLat.x), ncol=2),
                                   matrix(c(recvDeployLon.y, recvDeployLat.y), ncol=2))) ## bearing (see package geosphere for help)
  return(data)
}
