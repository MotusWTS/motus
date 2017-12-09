#' General summary of detections for each tag
#'
#' Creates a summary for each tag of it's first and last detection time, first and last detection site,
#' length of time between first and last detection,  straight line distance between first and last detection site,
#' rate of movement, and bearing
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, fullID, recvDeployLat, recvDeployLon, recvDepName, ts
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
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
#' }
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags, or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Create tag summary for all tags within detection data using tbl file tbl.alltags
#' tag_summary <- tagSum(tbl.alltags)
#' 
#' Create site summaries for only select tags using tbl file tbl.alltags
#' tag_summary <- tagSum(filter(tbl.alltags, motusTagID %in% c(16047, 16037, 16039)))
#'
#' Create site summaries for only a select species using data.frame df.alltags
#' tag_summary <- tagSum(filter(df.alltags, speciesEN == "Red Knot"))

tagSum <- function(data){
  data <- data %>% collect %>% as.data.frame
  data$ts <- as_datetime(data$ts, tz = "UTC")
  grouped <- dplyr::group_by(data, fullID)
  tmp <- dplyr::summarise(grouped,
                    first_ts=min(ts),
                    last_ts=max(ts),
                    tot_ts = difftime(max(ts), min(ts), units = "secs"),
                    num_det = length(ts)) ## total time in seconds
  tmp <- merge(tmp, subset(data, select = c(ts, fullID, recvDepName, recvDeployLat, recvDeployLon)),
               by.x = c("first_ts", "fullID"), by.y = c("ts", "fullID"), all.x = TRUE)
  tmp <- unique(merge(tmp, subset(data, select = c(ts, fullID, recvDepName, recvDeployLat, recvDeployLon)),
               by.x = c("last_ts", "fullID"), by.y = c("ts", "fullID"), all.x = TRUE))
  tmp <- dplyr::rename(tmp, first_site = recvDepName.x, last_site = recvDepName.y)
  tmp$dist <- with(tmp, latLonDist(recvDeployLat.x, recvDeployLat.x, recvDeployLat.y, recvDeployLat.y)) ## distance in meters
  tmp$rate <- with(tmp, dist/(as.numeric(tot_ts))) ## rate of travel in m/s
  tmp$bearing <- with(tmp, geosphere::bearing(matrix(c(recvDeployLat.x, recvDeployLat.x), ncol=2),
                                                 matrix(c(recvDeployLat.y, recvDeployLat.y), ncol=2))) ## bearing (see package geosphere for help)
#  tmp$rhumbline_bearing <- with(tmp, geosphere::bearingRhumb(matrix(c(recvDeployLat.x, recvDeployLat.x), ncol=2),
#                                                        matrix(c(recvDeployLat.y, recvDeployLat.y), ncol=2))) ## rhumbline bearing (see package geosphere for help)
  return(tmp[c("fullID", "first_ts", "last_ts", "first_site", "last_site", "recvDeployLat.x", "recvDeployLat.y",
               "tot_ts", "dist", "rate", "bearing", "num_det")])
}
