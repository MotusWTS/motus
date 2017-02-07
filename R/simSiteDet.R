#' Create a dataframe of simultaneous detections at multiple sites
#'
#' Creates a dataframe consisting of detections of tags that are detected at one or more receiver
#' at the same time.
#'
#' @param data dataframe of Motus detection data
#' @export
#' @examples
#' simSiteDet(dat)

## find a way to include distance between simultaneous detections
## below code with function sim will NOT work if there are simultaneous detections at more than 2 sites
simSiteDet <- function(data){
  data$dup <- duplicated(data[c("fullID","ts")]) | duplicated(data[c("fullID","ts")], fromLast = TRUE)
  data$dup <- ifelse(data$dup == TRUE,
                  duplicated(data[c("fullID","ts", "site")]) | duplicated(data[c("fullID","ts", "site")], fromLast = TRUE),
                  "dup")
  data$dup <- ifelse(data$dup == "FALSE",
                  "TRUE",
                  "FALSE")
  data <- subset(data, dup == TRUE, select = -c(dup))
  return(data)
}
