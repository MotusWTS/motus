#' Map of tag routes and sites coloured by id
#'
#' Google map of routes of Motus tag detections coloured by ID.  User defines a date range to show
#' points for receivers that were operational at some point during the date range.
#'
#' @param data dataframe of Motus detection data
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
#' Plot routemap of all detection data, with "terrain" type, and receivers active between 2016-01-01 and 2017-01-01
#' plotRouteMap(site_data = locs, detection_data = dat, maptype = "terrain",
#' latCentre = 44, lonCentre = -70, zoom = 5, startTime = "2016-01-01", endTime = "2016-12-31")
#' 
#' Plot routemap for a subset of one species
#' plotRouteMap(site_data = locs, detection_data = filter(tmp, spEN == "Swainson's Thrush"), maptype = "satellite",
#' latCentre = 50, lonCentre = -60, zoom = 3, startTime = "2016-01-01", endTime = "2016-12-31")

plotRouteMap 
fun <- function(data, site_data, zoom, latCentre, lonCentre, maptype, recvStart, recvEnd){
  if(class(zoom) != "numeric") stop('Numeric value 3-21 required for "zoom"')
  if(class(latCentre) != "numeric") stop('Numeric value required for "latCentre"')
  if(class(lonCentre) != "numeric") stop('Numeric value required for "lonCentre"')
  site_data$dtStart <- strptime(site_data$dtStart, "%Y-%m-%d %H:%M:%S")
  site_data$dtStart <- as.POSIXct(site_data$dtStart, tz = "UTC") ## convert start times to POSIXct
  site_data$dtEnd <- strptime(site_data$dtEnd, "%Y-%m-%d %H:%M:%S")
  site_data$dtEnd <- as.POSIXct(site_data$dtEnd, tz = "UTC") ## convert end times to POSIXct
  site_data$dtEnd <-as.POSIXct(ifelse(is.na(site_data$dtEnd),
                                       as.POSIXct(format(Sys.time(), "%Y-%m-%d %H:%M:%S")) + lubridate::dyears(1),
                                       site_data$dtEnd), tz = "UTC", origin = "1970-01-01") ## for sites with no end date, make an end date a year from now
  site_data <- unique(subset(site_data, select = c(deploymentName, latitude, longitude, dtStart, dtEnd)))
  siteOp <- with(site_data, lubridate::interval(dtStart, dtEnd)) ## get running intervals for each deployment
  dateRange <- lubridate::interval(as.POSIXct(recvStart), as.POSIXct(recvEnd)) ## get time interval you are interested in
  site_data$include <- lubridate::int_overlaps(siteOp, dateRange) ## if include == TRUE then the intervals overlapped and the site was "running" at some point during the specified time
  data <- select(data, motusTagID, ts, lat, lon, fullID, site) %>% distinct %>% collect %>% as.data.frame
  data$ts <- lubridate::as_datetime(data$ts, tz = "UTC")
  data <- data[order(data$ts),] ## order by time
  gmap <-  ggmap::get_map(location = c(lon = lonCentre, lat = latCentre), ## lon/lat to centre map over
                   maptype = maptype, ## select maptype
                   source = "google",
                   zoom = zoom) ## zoom, must be a whole number
  p <- ggmap::ggmap(gmap)
  p + ggplot2::geom_point(data = subset(site_data, include == TRUE), ggplot2::aes(longitude, latitude), pch=21, colour = "black", fill = "yellow") +
    ggplot2::geom_path(data=data, ggplot2::aes(lon, lat, group=fullID, col = fullID)) +
    ggplot2::labs(x = "Longitude", y = "Latitude") + ggplot2::theme_bw()
}
