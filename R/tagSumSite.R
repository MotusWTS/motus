#' Summarize detections of all tags by site
#'
#' Creates a summary for each tag of it's first and last detection time at each site,
#' length of time between first and last detection of each site, and total number of detections at each site
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables motusTagID, fullID, site, ts
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
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
#' Create tag summaries for all tags within detection data with time in minutes
#' tag_site_summary <- tagSumSite(alltags, units = "mins")
#' 
#' Create tag summaries for only select tags with time in default hours
#' tag_site_summary <- tagSumSite(filter(alltags, motusTagID %in% c(16047, 16037, 16039)))
#'
#' Create tag summaries for only a select species
#' tag_site_summary <- tagSumSite(filter(alltags, spEN == "Red Knot))

tagSumSite <- function(data, units = "hours"){
  data <- select(data, motusTagID, fullID, site, ts) %>% distinct %>% collect %>% as.data.frame
  data$ts <- as_datetime(data$ts, tz = "UTC")
  grouped <- dplyr::group_by(data, fullID, site)
  data <- dplyr::summarise(grouped,
                    first_ts=min(ts),
                    last_ts=max(ts),
                    tot_ts = difftime(max(ts), min(ts), units = units),
                    num_det = length(ts))
  return(data)
}
