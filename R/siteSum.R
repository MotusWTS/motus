#' Summarize and plot detections of all tags by site
#'
#' Creates a summary of the first and last detection at a site, the length of time between first and last detection,
#' the number of tags, and the total number of detections at a site.  Plots total number of detections across all tags,
#' and total number of tags detected at each site.
#'
#' @param data dataframe of Motus detection data
#' @param units units to display time difference, defaults to "hours", options include "secs", "mins", "hours", "days", "weeks"
#' @export
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
#' site_summary <- siteSum(dat, units = "mins")

siteSum <- function(data, site, fullID, ts, units = "hours"){
  data <- within(data, site <- reorder(site, (lat))) ## order site by latitude
  grouped <- dplyr::group_by(data, site)
  data <- dplyr::summarise(grouped,
                 first_ts=min(ts),
                 last_ts=max(ts),
                 tot_ts = difftime(max(ts), min(ts), units = units),
                 num.tags = length(unique(fullID)),
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
