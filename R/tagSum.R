#' General summary of detections for each tag
#'
#' Creates a summary for each tag of it's first and last detection time, first and last detection site,
#' length of time between first and last detection,  straight line distance between first and last detection site,
#' rate of movement, and bearing
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables motusTagID, fullID, recvDeployLat, recvDeployLon, recvDepName, ts
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
#' Create tag summary for all tags within detection data
#' tag_summary <- tagSum(alltags)
#' 
#' Create site summaries for only select tags
#' tag_summary <- tagSum(filter(alltags, motusTagID %in% c(16047, 16037, 16039)))
#'
#' Create site summaries for only a select species
#' tag_summary <- tagSum(filter(alltags, spEN == "Red Knot))

tagSum <- function(data){
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
