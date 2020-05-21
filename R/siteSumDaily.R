#' Summarize daily detections of all tags by site
#'
#' Creates a summary of the first and last daily detection at a site, the length
#' of time between first and last detection, the number of tags, and the total
#' number of detections at a site for each day. Same as siteSum, but daily by
#' site.
#'
#' @param data a selected table from .motus data, eg. "alltagsGPS", or a
#'   data.frame of detection data including at a minimum variables for
#'   motusTagID, sig, recvDeployName, ts
#' @param units units to display time difference, defaults to "hours", options
#'   include "secs", "mins", "hours", "days", "weeks"
#'
#' @return a data.frame with these columns:
#' - recvDeployName: site name of deployment
#' - date: date that is being summarized
#' - first_ts: time of first detection on specified "date" at "recvDeployName"
#' - last_ts: time of last detection on specified "date" at "recvDeployName"
#' - tot_ts: total amount of time between first and last detection at
#' "recvDeployName" on "date, output in specified unit (defaults to "hours")
#' - num.tags: total number of unique tags detected at "recvDeployName", on "date"
#' - num.det: total number of detections at "recvDeployName", on "date"
#'
#' @export
#'
#' @examples
#' # You can use either a selected tbl from .motus eg. "alltagsGPS", or a
#' # data.frame, instructions to convert a .motus file to all formats are below.
#' 
#' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
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
#' # Create site summaries for all sites within detection data with time in
#' # minutes using tbl file tbl.alltags
#' daily_site_summary <- siteSumDaily(tbl.alltags, units = "mins")
#' 
#' # Create site summaries for only select sites with time in minutes using tbl
#' # file tbl.alltags
#' sub <- filter(tbl.alltags, recvDeployName %in% c("Niapiskau", "Netitishi", 
#'                                                  "Old Cut", "Washkaugou"))
#' daily_site_summary <- siteSumDaily(sub, units = "mins")
#'
#' # Create site summaries for only a select species, Red Knot, with default
#' # time in hours using data frame df.alltags
#' daily_site_summary <- siteSumDaily(filter(df.alltags,
#'                                           speciesEN == "Red Knot"))

siteSumDaily <- function(data, units = "hours"){
  data <- dplyr::select(data, "motusTagID", "sig", "recvDeployName", "recvDeployLat", 
                        "recvDeployLon", "gpsLat", "gpsLon", "ts") %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    dplyr::mutate(recvLat = dplyr::if_else((is.na(.data$gpsLat)|.data$gpsLat == 0|.data$gpsLat ==999),
                                           .data$recvDeployLat,
                                           .data$gpsLat),
                  recvLon = dplyr::if_else((is.na(.data$gpsLon)|.data$gpsLon == 0|.data$gpsLon == 999),
                                           .data$recvDeployLon,
                                           .data$gpsLon),
                  recvDeployName = paste(.data$recvDeployName, 
                                         round(.data$recvLat, digits = 1), sep = "\n" ),
                  recvDeployName = paste(.data$recvDeployName,
                                         round(.data$recvLon, digits = 1), sep = ", "),
                  ts = lubridate::as_datetime(.data$ts, tz = "UTC"),
                  date = lubridate::as_date(.data$ts)) %>%
    as.data.frame()
  
  #data$date <- as.Date(data$ts)
  grouped <- dplyr::group_by(data, .data$recvDeployName, .data$date)
  site_sum <- dplyr::summarise(grouped,
                               first_ts=min(.data$ts),
                               last_ts=max(.data$ts),
                               tot_ts = difftime(max(.data$ts), min(.data$ts), units = units),
                               num_tags = length(unique(.data$motusTagID)),
                               num_det = length(.data$ts))
  site_sum <- as.data.frame(site_sum)
  return(site_sum)
}
