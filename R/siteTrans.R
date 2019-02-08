#' Summarize transitions between sites for each tag
#'
#' Creates a dataframe of transitions between sites; detections are ordered by
#' detection time, then "transitions" are identified as the period between the
#' final detection at site x (possible "departure"), and the first detection
#' (possible "arrival") at site y (ordered chronologically). Each row contains
#' the last detection time and lat/lon of site x, first detection time and
#' lat/lon of site y, distance between the site pair, time between detections,
#' rate of movement between detections, and bearing between site pairs.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame
#'   of detection data including at a minimum variables for ts, motusTagID,
#'   tagDeployID, recvDeployName, and a latitude/longitude
#' @param latCoord a variable with numeric latitude values, defaults to
#'   recvDeployLat
#' @param lonCoord a variable with numeric longitude values, defaults to
#'   recvDeployLon
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
#' # You can use either a selected tbl from .motus eg. "alltags", or a data.frame,
#' instructions to convert a .motus file to all formats are below. 
#' 
#' \dontrun{
#'   # download and access data from project 176 in sql format 
#'   sql.motus <- tagme(176, new = TRUE, update = TRUE) 
#'  
#'   # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#'   tbl.alltags <- tbl(sql.motus, "alltags") 
#'  
#'   ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#'    df.alltags <- tbl.alltags %>%
#'      collect %>%
#'      as.data.frame()
#' 
#'   # View all site transitions for all detection data from tbl file tbl.alltags
#'   transitions <- siteTrans(tbl.alltags)
#' 
#'   # View site transitions for only tag 16037 from data.frame df.alltags using
#'   # gpsLat/gpsLon
#'   transitions <- siteTrans(filter(df.alltags, motusTagID == 16037),
#'                            latCoord = "gpsLat", lonCoord = "gpsLon")
#' }

siteTrans <- function(data, latCoord = "recvDeployLat", lonCoord = "recvDeployLon"){
  tmp <- if(any(class(data) == "data.frame")){
    tmp = data
  } else {
    tmp = data %>% 
      collect() %>% 
      as.data.frame()
  }
  data <- dplyr::rename(tmp, lat = latCoord, lon = lonCoord) %>%
    ## get only relevant columns
    dplyr::select("ts", "motusTagID", "tagDeployID", "lat", "lon", "recvDeployName") %>%
    dplyr::mutate(recvDeployName = paste(recvDeployName, 
                                         round(lat, digits = 1), sep = "_" ),
                  recvDeployName = paste(recvDeployName,
                                         round(lon, digits = 1), sep = ", "),
                  ts = lubridate::as_datetime(ts, tz = "UTC")) %>% 
    dplyr::group_by(motusTagID, tagDeployID) %>% 
    tidyr::nest() %>%
    dplyr::mutate(consec = purrr::map(data, consec.fun),
                  site = purrr::map(consec, site.fun))
  
  trans <- tidyr::unnest(data, site) %>%
    dplyr::mutate(tot_ts = difftime(ts.y, ts.x, units = "secs"),
                  dist = latLonDist(lat.x, lon.x, lat.y, lon.y), ## distance in meters
                  rate = dist/(as.numeric(tot_ts)), ## rate of travel in m/s
                  ## bearing (see package geosphere for help)
                  bearing = geosphere::bearing(matrix(c(lon.x, lat.x), ncol=2),
                                               matrix(c(lon.y, lat.y), ncol=2)))
  
  trans
}
