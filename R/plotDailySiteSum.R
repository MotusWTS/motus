#' Plots number of detections and tags, daily, for a specified site
#'
#' Plots total number of detections across all tags, and total number of tags detected per day for
#' a specified site.  Depends on siteSumDaily function.
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables motusTagID, sig, site, ts
#' @param Site name of site to plot
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
#' Plot of all tag detections at site Longridge
#' plotDailySiteSum(alltags, sitename = "Longridge")

plotDailySiteSum <- function(data, sitename){
  tmp <- if(class(data) == "data.frame"){
    tmp = data
  } else {
    tmp = data %>% collect %>% as.data.frame
  }
  sitesum <- siteSumDaily(filter(data, site == sitename))
  detections <- ggplot2::ggplot(sitesum, ggplot2::aes(date, num_det)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates bar plot by site
    ggplot2::labs(x= "Date", y = "Total detections")
  tags <- ggplot2::ggplot(sitesum, ggplot2::aes(date, num_tags)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates line graph by site
    ggplot2::labs(x= "Date", y = "Number of tags")
  gridExtra::grid.arrange(detections, tags, nrow = 2, top = paste("Daily number of detections and tags at", sitename, sep = " "))
}
