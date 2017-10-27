#' Summarize and plot detections of all tags by site
#'
#' Creates a summary of the first and last detection at a site, the length of time between first and last detection,
#' the number of tags, and the total number of detections at a site.  Plots total number of detections across all tags,
#' and total number of tags detected at each site.
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables motusTagID, sig, lat, site, ts
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
#' Create site summaries for all sites within detection data with time in default hours
#' site_summary <- siteSum(alltags)
#' 
#' Create site summaries for only select sites with time in minutes
#' site_summary <- siteSum(filter(alltags, site %in% c("Niapiskau", "Netitishi", "Old Cur", "Washkaugou")), units = "mins")
#'
#' Create site summaries for only a select species
#' site_summary <- siteSum(filter(alltags, spEN == "Red Knot"))

siteSum <- function(data, units = "hours"){
  data <- select(data, motusTagID, sig, lat, site, ts) %>% distinct %>% collect %>% as.data.frame
  data <- within(data, site <- reorder(site, (lat))) ## order site by latitude
  data$ts <- as_datetime(data$ts, tz = "UTC")
  grouped <- dplyr::group_by(data, site)
  data <- dplyr::summarise(grouped,
                 first_ts=min(ts),
                 last_ts=max(ts),
                 tot_ts = difftime(max(ts), min(ts), units = units),
                 num.tags = length(unique(motusTagID)),
                 num.det = length(ts))
  detections <- ggplot2::ggplot(data = data, ggplot2::aes(x = site, y = num.det)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +  ## make x-axis labels on a 45º angle to read more easily
    ggplot2::labs(title = "Total number of detections per site, across all tags", x= "Site", y = "Total detections") ## changes x- and y-axis label
  tags <- ggplot2::ggplot(data = data, ggplot2::aes(x = site, y = num.tags)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates bar plot by site
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) + ## make x-axis labels on a 45º angle to read more easily
    ggplot2::labs(title = "Total number of tags detected per site", x= "Site", y = "Number of tags") ## changes x- and y-axis label
  gridExtra::grid.arrange(detections, tags, nrow = 2)
  return(data)
}
