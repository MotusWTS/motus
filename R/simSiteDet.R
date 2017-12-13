#' Create a dataframe of simultaneous detections at multiple sites
#'
#' Creates a dataframe consisting of detections of tags that are detected at two or more receiver
#' at the same time.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for motusTagID, recvDepName, ts
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags", or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' To get a data.frame of just simultaneous detections from a tbl file tbl.alltags
#' simSites <- simSiteDet(tbl.alltags)
#' 
#' To get a data.frame of just simultaneous detections from a dataframe df.alltags
#' simSites <- simSiteDet(df.alltags)

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
