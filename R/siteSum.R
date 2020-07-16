#' Summarize and plot detections of all tags by site
#'
#' Creates a summary of the first and last detection at a site, the length of
#' time between first and last detection, the number of tags, and the total
#' number of detections at a site.  Plots total number of detections across all
#' tags, and total number of tags detected at each site.
#' 
#' @param data a selected table from .motus data, eg. "alltagsGPS", or a
#'   data.frame of detection data including at a minimum variables for
#'   motusTagID, sig, recvDeployLat, recvDeployLon, recvDeployName, ts, gpsLat,
#'   and gpsLon
#' @param units units to display time difference, defaults to "hours", options
#'   include "secs", "mins", "hours", "days", "weeks"
#' @export
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
#' # default hours using data.frame df.alltags
#' site_summary <- siteSum(tbl.alltags)
#' 
#' # Create site summaries for only select sites with time in minutes
#' sub <- filter(df.alltags, recvDeployName %in% 
#'                 c("Niapiskau", "Netitishi", "Old Cur", "Washkaugou"))
#' site_summary <- siteSum(sub, units = "mins")
#'
#' # Create site summaries for only a select species, Red Knot
#' site_summary <- siteSum(filter(df.alltags, speciesEN == "Red Knot"))

siteSum <- function(data, units = "hours"){
  data <- dplyr::select(data, "motusTagID", "sig", "recvDeployLat", "recvDeployLon", 
                        "gpsLat", "gpsLon", "recvDeployName", "ts") %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    dplyr::mutate(recvLat = dplyr::if_else((is.na(.data$gpsLat)|.data$gpsLat == 0|.data$gpsLat ==999),
                                           .data$recvDeployLat,
                                           .data$gpsLat),
                  recvLon = dplyr::if_else((is.na(.data$gpsLon)|.data$gpsLon == 0|.data$gpsLon == 999),
                                           .data$recvDeployLon,
                                           .data$gpsLon),
                  recvDeployName = paste(.data$recvDeployName, 
                                         round(.data$recvLat, digits = 1), sep = "_" ),
                  recvDeployName = paste(.data$recvDeployName,
                                         round(.data$recvLon, digits = 1), sep = ", "),
                  ts = lubridate::as_datetime(.data$ts, tz = "UTC")) %>%
    dplyr::mutate(recvDeployName = stats::reorder(.data$recvDeployName, 
                                                  .data$recvLat)) %>% ## order site by latitude
    as.data.frame()
  
  #  data$ts <- as_datetime(data$ts, tz = "UTC")
  grouped <- dplyr::group_by(data, .data$recvDeployName)
  data <- dplyr::summarise(grouped,
                           first_ts=min(.data$ts),
                           last_ts=max(.data$ts),
                           tot_ts = difftime(max(.data$ts), min(.data$ts), units = units),
                           num.tags = length(unique(.data$motusTagID)),
                           num.det = length(.data$ts))
  
  detections <- ggplot2::ggplot(data = data, ggplot2::aes_string(x = "recvDeployName", y = "num.det")) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +  ## make x-axis labels on a 45 deg angle to read more easily
    ggplot2::labs(title = "Total number of detections per recvDeployName, across all tags", x= "Site", y = "Total detections") ## changes x- and y-axis label
  tags <- ggplot2::ggplot(data = data, ggplot2::aes_string(x = "recvDeployName", y = "num.tags")) +
    ggplot2::geom_bar(stat = "identity") + 
    ggplot2::theme_bw() + ## creates bar plot by recvDeployName
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) + ## make x-axis labels on a 45 deg angle to read more easily
    ggplot2::labs(title = "Total number of tags detected per site", x= "Site", y = "Number of tags") ## changes x- and y-axis label
  gridExtra::grid.arrange(detections, tags, nrow = 2)
  return(data)
}
