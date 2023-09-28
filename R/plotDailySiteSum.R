#' Plots number of detections and tags, daily, for a specified site
#'
#' Plots total number of detections across all tags, and total number of tags
#' detected per day for a specified site.  Depends on `siteSumDaily()`.
#'
#' @param data a selected table from .motus data, eg. "alltagsGPS", or a
#'   data.frame of detection data including at a minimum variables for
#'   `motusTagID`, `sig`, `recvDeployName`, `ts`
#' @param recvDeployName name of site to plot
#' 
#' @export
#' 
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#' 
#' # convert sql file "sql_motus" to a tbl called "tbl_alltags"
#' library(dplyr)
#' tbl_alltags <- tbl(sql_motus, "alltagsGPS") 
#' 
#' # convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
#' df_alltags <- tbl_alltags %>% 
#'   collect() %>% 
#'   as.data.frame() 
#' 
#' # Plot of all tag detections at site Longridge using dataframe df_alltags
#' plotDailySiteSum(df_alltags, recvDeployName = "Longridge")
#' 
#' # Plot of all tag detections at site Niapiskau using tbl file tbl_alltags
#' plotDailySiteSum(df_alltags, recvDeployName = "Niapiskau")

plotDailySiteSum <- function(data, recvDeployName){
  tmp <- if(any(class(data) == "data.frame")){
    tmp <- data
  } else {
    tmp <- data %>% dplyr::collect() %>% as.data.frame()
  }
  sitesum <- siteSumDaily(dplyr::filter(data, .data$recvDeployName == !!recvDeployName))
  detections <- ggplot2::ggplot(sitesum, ggplot2::aes_string(x = "date", y = "num_det")) +
    ggplot2::geom_bar(stat = "identity") + 
    ggplot2::theme_bw() + ## creates bar plot by recvDeployName
    ggplot2::labs(x= "Date", y = "Total detections")
  tags <- ggplot2::ggplot(sitesum, ggplot2::aes_string(x = "date", y = "num_tags")) +
    ggplot2::geom_bar(stat = "identity") + 
    ggplot2::theme_bw() + ## creates line graph by recvDeployName
    ggplot2::labs(x = "Date", y = "Number of tags")
  gridExtra::grid.arrange(detections, tags, nrow = 2, top = paste("Daily number of detections and tags at", recvDeployName, sep = " "))
}
