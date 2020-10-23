#' Plot all tag detections by latitude or longitude
#'
#' Plot latitude/longitude vs time (UTC rounded to the hour) for each tag using
#' .motus detection data. Coordinate is by default taken from a receivers
#' deployment latitude in metadata.
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame
#'   of detection data including at a minimum variables for recvDeployName,
#'   fullID, mfgID, date/time, latitude or longitude
#' @param tagsPerPanel number of tags in each panel of the plot, by default this
#'   is 5
#' @param coordinate column name from which to obtain location values, by
#'   default it is set to recvDeployLat
#' @param ts column for a date/time object as numeric or POSIXct, defaults to ts
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
#' # Plot tbl file tbl.alltags with default GPS latitude data and 5 tags per panel
#' plotAllTagsCoord(tbl.alltags)
#' 
#' # Plot an sql file tbl.alltags with 10 tags per panel
#' plotAllTagsCoord(tbl.alltags, tagsPerPanel = 10)
#' 
#' # Plot dataframe df.alltags using receiver deployment latitudes with default
#' # 5 tags per panel
#' plotAllTagsCoord(df.alltags, coordinate = "recvDeployLat")
#' 
#' # Plot dataframe df.alltags using LONGITUDES and 10 tags per panel
#' # But only works if non-NA "gpsLon"!
#' \dontrun{plotAllTagsCoord(df.alltags, coordinate = "gpsLon", tagsPerPanel = 10)}

#' # Plot dataframe df.alltags using lat for select motus tagIDs
#' plotAllTagsCoord(filter(df.alltags, motusTagID %in% c(19129, 16011, 17357)), 
#'                  tagsPerPanel = 1)

## grouping code taken from sensorgnome package

plotAllTagsCoord <- function(data, coordinate = "recvDeployLat", ts = "ts", tagsPerPanel = 5) {
  if(class(tagsPerPanel) != "numeric") stop('Numeric value required for "tagsPerPanel"', call. = FALSE)

  data <- data %>%
    dplyr::mutate(hour = 3600*round(as.numeric(.data$ts)/3600, 0)) %>% ## round times to the hour
    dplyr::filter(!!rlang::sym(coordinate) != 0)

  # Left-join summaries back in because these databases don't support mutate for mean/min/max etc.
  data <- data %>%
    dplyr::group_by(.data$recvDeployName) %>% 
    ## get summary of mean lats by recvDeployName
    dplyr::summarize(meanlat = mean(!!rlang::sym(coordinate), na.rm = TRUE)) %>%    
    dplyr::left_join(data, ., by = "recvDeployName") %>%
    dplyr::select("mfgID", "recvDeployName", "hour", "meanlat", "fullID") %>% 
    dplyr::distinct() %>% 
    dplyr::collect() %>% 
    dplyr::mutate(hour = lubridate::as_datetime(.data$hour, tz = "UTC"))
  
  if(nrow(data) == 0) stop("No data with coordinate '", coordinate, "'", 
                           call. = FALSE)

  labs = data$fullID[order(data$mfgID, data$fullID)]
  dup = duplicated(labs)
  tagLabs = labs[!dup]
  tagGroupIDs = data$mfgID[order(data$mfgID, data$fullID)][!dup]
  tagGroup = 1 + floor((0:length(tagLabs))/tagsPerPanel)
  ngroup = length(tagGroup)
  names(tagGroup) = tagLabs
  tagGroupFactor = tagGroup[as.character(data$fullID)]
  tagGroupLabels = tapply(tagGroupIDs, 1 + floor((0:(length(tagGroupIDs) - 
                                                       1))/tagsPerPanel), function(data) paste("IDs:", paste(sort(unique(data)), 
                                                                                                             collapse = ",")))
  data$tagGroupFactor = factor(tagGroupFactor, labels = tagGroupLabels, 
                               ordered = TRUE)
  data <- unique(subset(data, select = c("hour", "meanlat", 
                                         "recvDeployName", "fullID", "tagGroupFactor")))
  data <- data[order(data$hour), ]
  out <- by(data, INDICES = data$tagGroupFactor, FUN = function(m) {
    m <- droplevels(m)
    m <- ggplot2::ggplot(m, ggplot2::aes_string(x = "hour", y = "meanlat", 
                                                colour = "fullID", group = "fullID"))
    m + ggplot2::geom_line() + 
      ggplot2::geom_point(pch = 21) + 
      ggplot2::theme_bw() +
      ggplot2::labs(title = "Detection time vs Latitude by Tag", 
                    x = "Date", y = paste0('mean_', coordinate), colour = "ID") + 
      ggplot2::facet_wrap("tagGroupFactor") +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
  })
  do.call(gridExtra::grid.arrange, out)
}

