#' Plot all tag detections by site
#'
#' Plot site (ordered by latitude) vs time for each tag
#'
#' @param data dataframe of Motus detection data
#' @param tagsPerPanel number of tags in each panel of the plot
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' plotAllTagsSite(dat, tagsPerPanel = 4)

## grouping code taken from sensorgnome package

plotAllTagsSite <- function(data, tagsPerPanel = n){
  data$round_ts <- as.POSIXct(round(data$ts, "hours")) ## round to the hour
  data <- data %>%
    dplyr::group_by(site) %>%
    dplyr::mutate(meanlat = mean(lat)) ## get mean latitude
  data$meanlat = round(data$meanlat, digits = 4) ## round to 4 significant digits
  data$sitelat <- as.factor(paste(data$site, data$meanlat, sep = " ")) ## new column with site and lat
  data <- within(data, sitelat <- reorder(sitelat, (lat))) ## order sitelat by latitude
  ## We want to plot multiple tags per panel, so sort their labels and create a grouping factor
  ## Note that labels are sorted in increasing order by ID
  labs = data$label[order(data$id,data$label)]
  dup = duplicated(labs)
  tagLabs = labs[!dup]
  tagGroupIDs = data$id[order(data$id,data$label)][!dup]
  tagGroup = 1 + floor((0:length(tagLabs)) / tagsPerPanel)
  ngroup = length(tagGroup)
  names(tagGroup) = tagLabs
  tagGroupFactor = tagGroup[as.character(data$label)]
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
      ggplot2::facet_wrap("tagGroupFactor")
  })
  do.call(gridExtra::grid.arrange, out)
}
