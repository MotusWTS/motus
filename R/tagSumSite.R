#' Summarize detections of all tags by site
#'
#' Creates a summary for each tag of it's first and last detection time at each site,
#' length of time between first and last detection of each site, and total number of detections at each site
#'
#' @param data dataframe of Motus detection data
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#' @export
#' @examples
#' tag_site_summary <- tagSumSite(dat, units = "mins")

tagSumSite <- function(data, units = "hours"){
  grouped <- dplyr::group_by(data, fullID, site)
  data <- dplyr::summarise(grouped,
                    first_ts=min(ts),
                    last_ts=max(ts),
                    tot_ts = difftime(max(ts), min(ts), units = units),
                    num_det = length(ts))
  return(data)
}
