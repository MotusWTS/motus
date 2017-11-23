#' Create a dataframe of simultaneous detections at multiple sites
#'
#' Creates a dataframe consisting of detections of tags that are detected at one or more receiver
#' at the same time.
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables motusTagID, site, ts
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
#' To get a data.frame of just simultaneous detections
#' tmp <- simSiteDet(alltags)

simSiteDet <- function(data){
  data <- data %>% distinct %>% collect %>% as.data.frame
  data$ts <- as_datetime(data$ts, tz = "UTC")
  tmp <- data %>% select(motusTagID, ts) %>% distinct ## get only fields we want duplicates of
  tmp$dup <- duplicated(tmp[c("motusTagID","ts")]) | duplicated(tmp[c("motusTagID","ts")], fromLast = TRUE) ## label all duplicates
  tmp <- unique(filter(tmp, dup == TRUE)) ## keep only duplicates
  tmp <- merge(tmp, select(data, motusTagID, ts, recvDepName), all.x = TRUE) ## merge to get sites of each duplicate ts and motusTagID
  tmp <- unique(tmp) ## remove duplicates
  tmp <- summarise(group_by(tmp, motusTagID, ts), num.dup = length(ts)) ## determine how many times each combo of motusTagID and ts show up
  tmp <- filter(tmp, num.dup > 1) ## remove any where number of duplicates is less than 1, because anything over 1 will have detections at more than one site
  tmp <- merge(tmp, data, all.x = TRUE) ## now merge the identified duplicates back with detection data so we have more info available
  tmp <- unique(tmp)
  return(tmp)
}
