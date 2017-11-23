#' Map of tag routes and sites coloured by id
#'
#' Google map of routes of Motus tag detections coloured by ID.  User defines a date range to show
#' points for receivers that were operational at some point during the date range.
#'
#' @param data a selected table from .motus data, eg. "alltags" or "alltagswithambigs"
#' @param site_data receiver metadata file
#' @param maptype google map type to display, can be: "terrain" , "roadmap", "satellite", or "hybrid"
#' @param latCentre latitude to centre map around
#' @param lonCentre longitude to centre map around
#' @param zoom integer for zoom 3-21, 3 being continent level, 10 being city-scale
#' @param recvStart start date for date range of active receivers
#' @param recvEnd end date for date range of active receivers
#' 
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' access the "all tags" table within the motus sql
#' tmp <- tbl(motusSqlFile, "alltags")
#' 
#' Plot routemap of all detection data, with "terrain" maptype, and receivers active between 2016-01-01 and 2017-01-01
#' plotRouteMap(tmp, maptype = "terrain", latCentre = 44, lonCentre = -70, zoom = 5, recvStart = "2016-01-01", recvEnd = "2016-12-31")
#' 
#' Plot routemap of only select species (Red Knot), with "satellite" maptype, and receivers active between 2015-01-01 and 2016-01-01
#' plotRouteMap(filter(tmp, speEN == "Red Knot"), maptype = "terrain", latCentre = 44, lonCentre = -70, zoom = 5, recvStart = "2016-01-01", recvEnd = "2016-12-31")

plotRouteMap <- function(data, file.name, zoom, latCentre, lonCentre, maptype, recvStart, recvEnd){
  if(class(zoom) != "numeric") stop('Numeric value 3-21 required for "zoom"')
  if(class(latCentre) != "numeric") stop('Numeric value required for "latCentre"')
  if(class(lonCentre) != "numeric") stop('Numeric value required for "lonCentre"')
  site <- src_sqlite(file.name)
  site <- tbl(site, "recvDeps")
  site <- site %>% select(name, latitude, longitude, tsStart, tsEnd) %>% distinct %>% collect %>% as.data.frame
  site <- site %>% mutate(tsStart = as_datetime(tsStart, tz = "UTC"),
                          tsEnd = as_datetime(tsEnd, tz = "UTC"))
  site$tsEnd <-as.POSIXct(ifelse(is.na(site$tsEnd),
                                       as.POSIXct(format(Sys.time(), "%Y-%m-%d %H:%M:%S")) + lubridate::dyears(1),
                                       site$tsEnd), tz = "UTC", origin = "1970-01-01") ## for sites with no end date, make an end date a year from now
  siteOp <- with(site, lubridate::interval(tsStart, tsEnd)) ## get running intervals for each deployment
  dateRange <- lubridate::interval(as.POSIXct(recvStart), as.POSIXct(recvEnd)) ## get time interval you are interested in
  site$include <- lubridate::int_overlaps(siteOp, dateRange) ## if include == TRUE then the intervals overlapped and the site was "running" at some point during the specified time
  data <- select(data, motusTagID, ts, recvDeployLat, recvDeployLon, fullID, recvDepName, speciesEN) %>% distinct %>% collect %>% as.data.frame
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  data <- data[order(data$ts),] ## order by time
  gmap <-  ggmap::get_map(location = c(lon = lonCentre, lat = latCentre), ## lon/lat to centre map over
                   maptype = maptype, ## select maptype
                   source = "google",
                   zoom = zoom) ## zoom, must be a whole number
  p <- ggmap::ggmap(gmap)
  p + ggplot2::geom_point(data = subset(site, include == TRUE), ggplot2::aes(longitude, latitude), pch=21, colour = "black", fill = "yellow") +
    ggplot2::geom_path(data=data, ggplot2::aes(recvDeployLon, recvDeployLat, group=fullID, col = fullID)) +
    ggplot2::labs(x = "Longitude", y = "Latitude") + ggplot2::theme_bw()
}
