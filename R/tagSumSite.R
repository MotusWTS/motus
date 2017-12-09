#' Summarize detections of all tags by site
#'
#' Creates a summary for each tag of it's first and last detection time at each site,
#' length of time between first and last detection of each site, and total number of detections at each site.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, fullID, recvDepName, ts
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags, or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Create tag summaries for all tags within detection data with time in minutes with tbl file tbl.alltags
#' tag_site_summary <- tagSumSite(tbl.alltags, units = "mins")
#' 
#' Create tag summaries for only select tags with time in default hours with data.frame df.alltags
#' tag_site_summary <- tagSumSite(filter(df.alltags, motusTagID %in% c(16047, 16037, 16039)))
#'
#' Create tag summaries for only a select species with data.frame df.alltags
#' tag_site_summary <- tagSumSite(filter(df.alltags, speciesEN == "Red Knot"))

tagSumSite <- function(data, units = "hours"){
  data <- select(data, motusTagID, fullID, recvDepName, ts) %>% distinct %>% collect %>% as.data.frame
  data$ts <- as_datetime(data$ts, tz = "UTC")
  grouped <- dplyr::group_by(data, fullID, recvDepName)
  data <- dplyr::summarise(grouped,
                    first_ts=min(ts),
                    last_ts=max(ts),
                    tot_ts = difftime(max(ts), min(ts), units = units),
                    num_det = length(ts))
  data <- as.data.frame(data)
  return(data)
}
