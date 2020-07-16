#' Create a dataframe of simultaneous detections at multiple sites
#'
#' Creates a dataframe consisting of detections of tags that are detected at two or more receiver
#' at the same time.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, recvDeployName, ts
#' @export
#'
#' @examples
#' # You can use either a selected tbl from .motus eg. "alltags", or a
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
#' tbl.alltags <- tbl(sql.motus, "alltags") 
#' 
#' # convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' df.alltags <- tbl.alltags %>% 
#'   collect() %>% 
#'   as.data.frame()
#' 
#' # To get a data.frame of just simultaneous detections from a tbl file
#' # tbl.alltags
#' simSites <- simSiteDet(tbl.alltags)
#' 
#' # To get a data.frame of just simultaneous detections from a dataframe
#' # df.alltags
#' simSites <- simSiteDet(df.alltags)

simSiteDet <- function(data){
  data <- data %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    as.data.frame()
  
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")

  tmp <- data %>% 
    dplyr::select("motusTagID", "ts") %>% 
    dplyr::distinct() ## get only fields we want duplicates of
  
  tmp$dup <- duplicated(tmp[c("motusTagID","ts")]) | duplicated(tmp[c("motusTagID","ts")], fromLast = TRUE) ## label all duplicates
  tmp <- unique(dplyr::filter(tmp, .data$dup == TRUE)) ## keep only duplicates
  tmp <- merge(tmp, dplyr::select(data, "motusTagID", "ts", "recvDeployName"), all.x = TRUE) ## merge to get sites of each duplicate ts and motusTagID
  tmp <- unique(tmp) ## remove duplicates
  tmp <- dplyr::group_by(tmp, .data$motusTagID, .data$ts) %>% 
    dplyr::summarise(num.dup = length(.data$ts)) ## determine how many times each combo of motusTagID and ts show up
  tmp <- dplyr::filter(tmp, .data$num.dup > 1) ## remove any where number of duplicates is less than 1, because anything over 1 will have detections at more than one site
  tmp <- merge(tmp, data, all.x = TRUE) ## now merge the identified duplicates back with detection data so we have more info available
  tmp <- unique(tmp)
  return(tmp)
}
