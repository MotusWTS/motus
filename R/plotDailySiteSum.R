#' Plots number of detections and tags, daily, for a specified site
#'
#' Plots total number of detections across all tags, and total number of tags detected per day for
#' a specified site.  Depends on siteSumDaily function.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, sig, recvDeployname, ts
#' @param recvDeployname name of site to plot
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags", or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Plot of all tag detections at site Longridge using dataframe df.alltags
#' plotDailySiteSum(df.alltags, recvDeployname = "Longridge")
#' 
#' Plot of all tag detections at site Niapiskau using tbl file tbl.alltags
#' plotDailySiteSum(df.alltags, recvDeployname = "Niapiskau")

plotDailySiteSum <- function(data, recvDeployname){
  tmp <- if(class(data) == "data.frame"){
    tmp = data
  } else {
    tmp = data %>% collect %>% as.data.frame
  }
  sitesum <- siteSumDaily(filter(data, recvDeployname == recvDeployname))
  detections <- ggplot2::ggplot(sitesum, ggplot2::aes(date, num_det)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates bar plot by recvDeployname
    ggplot2::labs(x= "Date", y = "Total detections")
  tags <- ggplot2::ggplot(sitesum, ggplot2::aes(date, num_tags)) +
    ggplot2::geom_bar(stat = "identity") + ggplot2::theme_bw() + ## creates line graph by recvDeployname
    ggplot2::labs(x= "Date", y = "Number of tags")
  gridExtra::grid.arrange(detections, tags, nrow = 2, top = paste("Daily number of detections and tags at", recvDeployname, sep = " "))
}
