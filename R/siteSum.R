#' Summarize and plot detections of all tags by site
#'
#' Creates a summary of the first and last detection at a site, the length of time between first and last detection,
#' the number of tags, and the total number of detections at a site.  Plots total number of detections across all tags,
#' and total number of tags detected at each site.
#' 
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, sig, recvDeployLat, recvDeployName, and ts
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @return a data.frame with these columns:
#' \itemize{
#' \item site: site
#' \item first_ts: time of first detection at specified site
#' \item last_ts: time of last detection at specified site
#' \item tot_ts: total amount of time between first and last detection at specified site, output in specified unit (defaults to "hours")
#' \item num.tags: total number of unique tags detected at specified site
#' \item num.det: total number of tag detections at specified site
#' }
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags", or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Create site summaries for all sites within detection data with time in default hours using data.frame df.alltags
#' site_summary <- siteSum(tbl.alltags)
#' 
#' Create site summaries for only select sites with time in minutes
#' site_summary <- siteSum(filter(df.alltags, recvDeployName %in% c("Niapiskau", "Netitishi", "Old Cur", "Washkaugou")), units = "mins")
#'
#' Create site summaries for only a select species, Red Knot
#' site_summary <- siteSum(filter(df.alltags, speciesEN == "Red Knot"))

siteSum <- function(data, units = "hours"){
  data <- select(data, motusTagID, sig, recvDeployLat, recvDeployLon, 
                 gpsLat, gpsLon, recvDeployName, ts) %>% distinct %>% collect %>% as.data.frame
  data <- mutate(data,
                 recvLat = if_else((is.na(gpsLat)|gpsLat == 0|gpsLat ==999),
                                   recvDeployLat,
                                   gpsLat),
                 recvLon = if_else((is.na(gpsLon)|gpsLon == 0|gpsLon == 999),
                                   recvDeployLon,
                                   gpsLon),
                 recvDeployName = paste(recvDeployName, 
                                        round(recvLat, digits = 1), sep = "_" ),
                 recvDeployName = paste(recvDeployName,
                                        round(recvLon, digits = 1), sep = ", "),
                 ts = lubridate::as_datetime(ts, tz = "UTC"))
  data <- within(data, recvDeployName <- reorder(recvDeployName, (recvLat))) ## order site by latitude
#  data$ts <- as_datetime(data$ts, tz = "UTC")
  grouped <- dplyr::group_by(data, recvDeployName)
  data <- dplyr::summarise(grouped,
                 first_ts=min(ts),
                 last_ts=max(ts),
                 tot_ts = difftime(max(ts), min(ts), units = units),
                 num.tags = length(unique(motusTagID)),
                 num.det = length(ts))
  detections <- ggplot2::ggplot(data = data, ggplot2::aes(x = recvDeployName, y = num.det)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +  ## make x-axis labels on a 45 deg angle to read more easily
    ggplot2::labs(title = "Total number of detections per recvDeployName, across all tags", x= "Site", y = "Total detections") ## changes x- and y-axis label
  tags <- ggplot2::ggplot(data = data, ggplot2::aes(x = recvDeployName, y = num.tags)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates bar plot by recvDeployName
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) + ## make x-axis labels on a 45 deg angle to read more easily
    ggplot2::labs(title = "Total number of tags detected per site", x= "Site", y = "Number of tags") ## changes x- and y-axis label
  gridExtra::grid.arrange(detections, tags, nrow = 2)
  return(data)
}
