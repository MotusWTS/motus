#' Plot all tag detections by site
#'
#' Plot site (ordered by latitude) vs time (UTC) for each tag
#'
#' @param data tbl file of .motus data
#' @param tagsPerPanel number of tags in each panel of the plot, default is 5
#' @param lat.name column of receivermlatitude values to use, defaults to GPS latitude
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' access the "all tags" table within the motus sql
#' tmp <- tbl(motusSqlFile, "alltags")
#' 
#' # Plot tbl file "tmp" with default GPS latitude data and 5 tags per panel
#' plotAllTagsSite(tmp)
#' 
#' # Plot tbl file "tmp" with 10 tags per panel
#' plotAllTagsSite(tmp, tagsPerPanel = 10)
#' 
#' # Plot tbl file "tmp" using receiver deployment latitudes with default 5 tags per panel
#' plotAllTagsSite(tmp, lat.name = "depLat")
#' 
#' # Plot tbl file "tmp" using lat and 1 tag per panel for select species and 3 tags per panel
#' plotAllTagsSite(filter(tmp, spEN == "Swainson's Thrush"), tagsPerPanel = 3)

## grouping code taken from sensorgnome package

plotAllTagsSite <- function(data, lat.name = "lat", tagsPerPanel = 5){
  if(class(tagsPerPanel) != "numeric") stop('Numeric value required for "tagsPerPanel"')
  data = data %>% mutate(round_ts = 3600*round(ts/3600, 0)) ## round times to the hour
  data = distinct(select(data, id, site, round_ts, lat, fullID))
  dataGrouped <- dplyr::filter_(data, paste(lat.name, "!=", 0)) %>% group_by(site) %>% 
    summarise_(.dots = setNames(paste0('mean(',lat.name,')'), 'meanlat')) ## get summary of mean lats by site
  data <- inner_join(data, dataGrouped, by = "site") ## join grouped data with data
  data <- select(data, id, site, round_ts, lat, meanlat, fullID) %>% distinct %>% collect %>% as.data.frame
  data$meanlat = round(data$meanlat, digits = 2) ## round to 2 significant digits
  data$sitelat <- as.factor(paste(data$site, data$meanlat, sep = " ")) ## new column with site and lat
  data <- within(data, sitelat <- reorder(sitelat, (lat))) ## order sitelat by latitude
  data$round_ts <- lubridate::as_datetime(data$round_ts, tz = "UTC")
  ## We want to plot multiple tags per panel, so sort their labels and create a grouping factor
  ## Note that labels are sorted in increasing order by ID
  labs = data$fullID[order(data$id,data$fullID)]
  dup = duplicated(labs)
  tagLabs = labs[!dup]
  tagGroupIDs = data$id[order(data$id,data$fullID)][!dup]
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
      ggplot2::labs(title = "Detection time vs Site (ordered by latitude) by Tag", x = "Date", y = "Latitude", colour = "ID") +
      ggplot2::facet_wrap("tagGroupFactor") + ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  do.call(gridExtra::grid.arrange, out)
}
