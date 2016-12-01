#' Plots number of detections and tags, daily, for a specified site
#'
#' Plots total number of detections across all tags, and total number of tags detected per day for
#' a specified site.  Depends on siteSumDaily function.
#'
#' @param data dataframe of Motus detection data
#' @param Site name of site to plot
#' @export
#' @examples
#' plotDailySiteSum(dat, Site = "Longridge")

plotDailySiteSum <- function(data, Site){
  sitesum <- siteSumDaily(subset(data, site == Site))
  detections <- ggplot2::ggplot(sitesum, ggplot2::aes(date, num_det)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates bar plot by site
    ggplot2::labs(x= "Date", y = "Total detections")
  tags <- ggplot2::ggplot(sitesum, ggplot2::aes(date, num_tags)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates line graph by site
    ggplot2::labs(x= "Date", y = "Number of tags")
  gridExtra::grid.arrange(detections, tags, nrow = 2, top = paste("Daily number of detections and tags at", Site, sep = " "))
}
