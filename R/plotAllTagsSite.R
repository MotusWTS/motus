#' Plot all tag detections by site
#'
#' Plot site (ordered by latitude) vs time (UTC) for each tag
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs", or a data.frame of detection data 
#' including at a minimum the variables id, recvDepName, ts, lat, fullID
#' @param tagsPerPanel number of tags in each panel of the plot, default is 5
#' @param coordinate column of receiver latitude/longitude values to use, defaults to recvDeployLat
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
#' Plot detections of all tags by site ordered by latitude, with default 5 tags per panel
#' plotAllTagsSite(alltags)
#' 
#' Plot detections of all tags by site ordered by latitude, with 10 tags per panel
#' plotAllTagsSite(alltags, tagsPerPanel = 10)
#' 
#' Plot detections of all tags by site ordered by receiver deployment latitude
#' plotAllTagsSite(alltags, coordinate = "recvDeployLon")
#' 
#' # Plot tbl file "tmp" using lat and 1 tag per panel for select species and 3 tags per panel
#' plotAllTagsSite(filter(alltags, spEN == "Red Knot"), coordinate = gpsLat, tagsPerPanel = 3)

## grouping code taken from sensorgnome package
plotAllTagsSite <- function(data, coordinate = "recvDeployLat", tagsPerPanel = 5){
  if(class(tagsPerPanel) != "numeric") stop('Numeric value required for "tagsPerPanel"')
  data = data %>% mutate(round_ts = 3600*round(as.numeric(ts)/3600, 0)) ## round times to the hour
  #data = distinct(select(data, id, site, round_ts, lat, recvDeployLat, lon, recvDeployLon, fullID))
  dataGrouped <- dplyr::filter_(data, paste(coordinate, "!=", 0)) %>% group_by(recvDepName) %>% 
    summarise_(.dots = setNames(paste0('mean(',coordinate,')'), 'meanlat')) ## get summary of mean lats by recvDepName
  data <- inner_join(data, dataGrouped, by = "recvDepName") ## join grouped data with data
  data <- select(data, mfgID, recvDepName, round_ts, meanlat, fullID) %>% distinct %>% collect %>% as.data.frame
  data$meanlat = round(data$meanlat, digits = 2) ## round to 2 significant digits
  data$sitelat <- as.factor(paste(data$recvDepName, data$meanlat, sep = " ")) ## new column with recvDepName and lat
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
