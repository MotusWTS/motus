#' Plot all tag detections by deployment
#'
#' Plot deployment (ordered by latitude) vs time (UTC) for each tag
#'
#' @param data a selected table from .motus data, eg. "alltags", or a data.frame of detection data 
#' including at a minimum variables for recvDeployName, fullID, mfgID, date/time, latitude or longitude
#' @param tagsPerPanel number of tags in each panel of the plot, default is 5
#' @param coordinate column of receiver latitude/longitude values to use, defaults to recvDeployLat
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' You can use either a selected tbl from .motus eg. "alltags", or a data.frame, instructions to convert a .motus file to all formats are below.
#' sql.motus <- tagme(176, new = TRUE, update = TRUE) # download and access data from project 176 in sql format
#' tbl.alltags <- tbl(sql.motus, "alltags") # convert sql file "sql.motus" to a tbl called "tbl.alltags"
#' df.alltags <- tbl.alltags %>% collect %>% as.data.frame() ## convert the tbl "tbl.alltags" to a data.frame called "df.alltags"
#' 
#' Plot detections of dataframe df.alltags by site ordered by latitude, with default 5 tags per panel
#' plotAllTagsSite(df.alltags)
#' 
#' Plot detections of dataframe df.alltags by site ordered by latitude, with 10 tags per panel
#' plotAllTagsSite(df.alltags, tagsPerPanel = 10)
#' 
#' Plot detections of tbl file tbl.alltags by site ordered by receiver deployment latitude
#' plotAllTagsSite(tbl.alltags, coordinate = "recvDeployLon")
#' 
#' Plot tbl file tbl.alltags using gpsLat and 3 tags per panel for select species Red Knot
#' plotAllTagsSite(filter(tbl.alltags, speciesEN == "Red Knot"), coordinate = "gpsLat", tagsPerPanel = 3)

## grouping code taken from sensorgnome package
plotAllTagsSite <- function(data, coordinate = "recvDeployLat", tagsPerPanel = 5){
  if(class(tagsPerPanel) != "numeric") stop('Numeric value required for "tagsPerPanel"')
  data = data %>% mutate(round_ts = 3600*round(as.numeric(ts)/3600, 0)) ## round times to the hour
  #data = distinct(select(data, id, site, round_ts, lat, recvDeployLat, lon, recvDeployLon, fullID))
  dataGrouped <- dplyr::filter_(data, paste(coordinate, "!=", 0)) %>% group_by(recvDeployName) %>% 
    summarise_(.dots = setNames(paste0('mean(',coordinate,')'), 'meanlat')) ## get summary of mean lats by recvDeployName
  data <- inner_join(data, dataGrouped, by = "recvDeployName") ## join grouped data with data
  data <- select(data, mfgID, recvDeployName, round_ts, meanlat, fullID) %>% distinct %>% collect %>% as.data.frame
  data$meanlat = round(data$meanlat, digits = 2) ## round to 2 significant digits
  data$sitelat <- as.factor(paste(data$recvDeployName, data$meanlat, sep = " ")) ## new column with recvDeployName and lat
  data <- within(data, sitelat <- reorder(sitelat, (meanlat))) ## order sitelat by latitude
  data$round_ts <- lubridate::as_datetime(data$round_ts, tz = "UTC")
  ## We want to plot multiple tags per panel, so sort their labels and create a grouping factor
  ## Note that labels are sorted in increasing order by ID
  labs = data$fullID[order(data$mfgID,data$fullID)]
  dup = duplicated(labs)
  tagLabs = labs[!dup]
  tagGroupIDs = data$mfgID[order(data$mfgID,data$fullID)][!dup]
  tagGroup = 1 + floor((0:length(tagLabs)) / tagsPerPanel)
  ngroup = length(tagGroup)
  names(tagGroup) = tagLabs
  tagGroupFactor = tagGroup[as.character(data$fullID)]
  tagGroupLabels = tapply(tagGroupIDs, 1 + floor((0:(length(tagGroupIDs)-1)) / tagsPerPanel), function(data) paste("IDs:", paste(sort(unique(data)), collapse=",")))
  data$tagGroupFactor = factor(tagGroupFactor, labels=tagGroupLabels, ordered=TRUE)
  data <- unique(subset(data, select = c(round_ts, meanlat, sitelat, fullID, tagGroupFactor))) ## get unique hourly detections for small dataframe
  data <- data[order(data$round_ts),] ## order by time
  out <- by(data, INDICES = data$tagGroupFactor, FUN = function(m){
    m <- droplevels(m)
    m <- ggplot2::ggplot(m, ggplot2::aes(round_ts, sitelat, colour = fullID, group = fullID))
    p <- ggplot2::ggplot(data, ggplot2::aes(round_ts, sitelat, col = fullID, group = fullID))
    m + ggplot2::geom_line() + ggplot2::geom_point(pch = 21) + ggplot2::theme_bw() +
      ggplot2::labs(title = "Detection time vs Site (ordered by latitude) by Tag", x = "Date", y = paste0('Site ordered by ',coordinate), colour = "ID") +
      ggplot2::facet_wrap("tagGroupFactor") + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  do.call(gridExtra::grid.arrange, out)
}
