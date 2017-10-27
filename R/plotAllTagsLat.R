#' Plot all tag detections by latitude
#'
#' Plot latitude vs time (UTC rounded to the hour) for each tag using .motus data.  Latitude is by default taken from a receivers GPS recordings.
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs"
#' @param tagsPerPanel number of tags in each panel of the plot, by default this is 5
#' @param coordinate column name from which to obtain location values, by default it is set to GPS latitude
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' access the "all tags" table within the motus sql
#' tmp <- tbl(motusSqlFile, "alltags")
#' 
#' # Plot tbl file "tmp" with default GPS latitude data and 5 tags per panel
#' plotAllTagsLat(tmp)
#' 
#' # Plot tbl file "tmp" with 10 tags per panel
#' plotAllTagsLat(tmp, tagsPerPanel = 10)
#' 
#' # Plot tbl file "tmp" using receiver deployment latitudes with default 5 tags per panel
#' plotAllTagsLat(tmp, coordinate = "depLat")
#' 
#' # Plot tbl file "tmp" using LONGITUDES and 10 tags per panel
#' plotAllTagsLat(tmp, coordinate = "lon", tagsPerPanel = 10)

#' # Plot tbl file "tmp" using lat and 10 tags per panel for select motus tagIDs
#' plotAllTagsLat(filter(tmp, motusTagID %in% c(9045, 10234, 96321)), tagsPerPanel = 10)

## grouping code taken from sensorgnome package

plotAllTagsLat <- function(data, coordinate = "lat", tagsPerPanel = 5) {
  if(class(tagsPerPanel) != "numeric") stop('Numeric value required for "tagsPerPanel"')
  data = data %>% mutate(hour = 3600*round(as.numeric(ts)/3600, 0)) ## round times to the hour
  dataGrouped <- dplyr::filter_(data, paste(coordinate, "!=", 0)) %>% group_by(site) %>% 
    summarise_(.dots = setNames(paste0('mean(',coordinate,')'), 'meanlat')) ## get summary of mean lats by site
  data <- inner_join(data, dataGrouped, by = "site") ## join grouped data with data
  data <- select(data, id, site, hour, lat, meanlat, fullID) %>% distinct %>% collect %>% as.data.frame
  data$hour <- lubridate::as_datetime(data$hour, tz = "UTC")
  labs = data$fullID[order(data$id, data$fullID)]
  dup = duplicated(labs)
  tagLabs = labs[!dup]
  tagGroupIDs = data$id[order(data$id, data$fullID)][!dup]
  tagGroup = 1 + floor((0:length(tagLabs))/tagsPerPanel)
  ngroup = length(tagGroup)
  names(tagGroup) = tagLabs
  tagGroupFactor = tagGroup[as.character(data$fullID)]
  tagGroupLabels = tapply(tagGroupIDs, 1 + floor((0:(length(tagGroupIDs) - 
                                                       1))/tagsPerPanel), function(data) paste("IDs:", paste(sort(unique(data)), 
                                                                                                             collapse = ",")))
  data$tagGroupFactor = factor(tagGroupFactor, labels = tagGroupLabels, 
                               ordered = TRUE)
  data <- unique(subset(data, select = c(hour, meanlat, 
                                         site, fullID, tagGroupFactor)))
  data <- data[order(data$hour), ]
  out <- by(data, INDICES = data$tagGroupFactor, FUN = function(m) {
    m <- droplevels(m)
    m <- ggplot2::ggplot(m, ggplot2::aes(hour, meanlat, 
                                         colour = fullID, group = fullID))
    m + ggplot2::geom_line() + ggplot2::geom_point(pch = 21) + 
      ggplot2::theme_bw() + ggplot2::labs(title = "Detection time vs Latitude by Tag", 
                                          x = "Date", y = paste0('mean_', coordinate), colour = "ID") + ggplot2::facet_wrap("tagGroupFactor") +
      ggplot2::theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  do.call(gridExtra::grid.arrange, out)
}

