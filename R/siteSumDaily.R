#' Summarize daily detections of all tags by site
#'
#' Creates a summary of the first and last daily detection at a site, the length of time between first and last detection,
#' the number of tags, and the total number of detections at a site for each day. Same as siteSum, but daily by site.
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs"
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#'
#' @return a data.frame with these columns:
#' \itemize{
#' \item site: site
#' \item date: date that is being summarised
#' \item first_ts: time of first detection on specified "date" at "site"
#' \item last_ts: time of last detection on specified "date" at "site"
#' \item tot_ts: total amount of time between first and last detection at "site" on "date, output in specified unit (defaults to "hours")
#' \item num.tags: total number of unique tags detected at "site", on "date"
#' \item num.det: total number of detections at "site", on "date"
#' }
#'
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' access the "all tags" table within the motus sql
#' tmp <- tbl(motusSqlFile, "alltags")
#' 
#' Create site summaries for all sites within detection data with time in minutes
#' daily_site_summary <- siteSumDaily(tmp, units = "mins")
#' 
#' Create site summaries for only select sites with time in minutes
#' daily_site_summary <- siteSumDaily(filter(tmp, site %in% c("Niapiskau", "Netitishi", "Old Cur", "Washkaugou")), units = "mins")
#'
#' Create site summaries for only a select species with default time in hours
#' daily_site_summary <- siteSumDaily(filter(tmp, spEN == "Red Knot))

siteSumDaily <- function(data, units = "hours"){
  data <- select(data, motusTagID, sig, site, ts) %>% distinct %>% collect %>% as.data.frame
  data$ts <- as_datetime(data$ts, tz = "UTC")
  data$date <- as.Date(data$ts)
  grouped <- dplyr::group_by(data, site, date)
  site_sum <- dplyr::summarise(grouped,
                        first_ts=min(ts),
                        last_ts=max(ts),
                        tot_ts = difftime(max(ts), min(ts), units = units),
                        num_tags = length(unique(motusTagID)),
                        num_det = length(ts))
}
