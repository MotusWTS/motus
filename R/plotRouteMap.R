#' Map of routes and sites coloured by id
#'
#' Google map of routes Motus detections coloured by ID, with sites that were operational
#' at some point during a user defined time interval
#'
#' @param data dataframe of Motus detection data
#' @export
#' @author Zoe Crysler \email{zcrysler@@gmail.com}
#'
#' @examples
#' plotRouteMap(site_data = locs, detection_data = dat, maptype = "terrain",
#' latCentre = 44, lonCentre = -70, zoom = 5, startTime = "2016-01-01", endTime = "2016-12-31")

plotRouteMap <- function(site_data, detection_data, zoom, latCentre, lonCentre,
                         maptype = c("satellite", "terrain", "hybrid", "roadmap"), startTime, endTime){
  site_data$dt_start <- strptime(site_data$dt_start, "%Y-%m-%d %H:%M:%S")
  site_data$dt_start <- as.POSIXct(site_data$dt_start, tz = "UTC") ## convert start times to POSIXct
  site_data$dt_end <- strptime(site_data$dt_end, "%Y-%m-%d %H:%M:%S")
  site_data$dt_end <- as.POSIXct(site_data$dt_end, tz = "UTC") ## convert end times to POSIXct
  site_data$dt_end <-as.POSIXct(ifelse(is.na(site_data$dt_end),
                                       as.POSIXct(format(Sys.time(), "%Y-%m-%d %H:%M:%S")) + lubridate::dyears(1),
                                       site_data$dt_end), tz = "UTC", origin = "1970-01-01") ## for sites with no end date, make an end date a year from now
  site_data <- unique(subset(site_data, select = c(name, latitude, longitude, dt_start, dt_end)))
  siteOp <- with(site_data, lubridate::interval(dt_start, dt_end)) ## get running intervals for each deployment
  dateRange <- lubridate::interval(as.POSIXct(startTime), as.POSIXct(endTime)) ## get time interval you are interested in
  site_data$include <- lubridate::int_overlaps(siteOp, dateRange) ## if include == TRUE then the intervals overlapped and the site was "running" at some point during the specified time
  detection_data <- detection_data[order(detection_data$ts),] ## order by time
  gmap <-  ggmap::get_map(location = c(lon = lonCentre, lat = latCentre), ## lon/lat to centre map over
                   maptype = maptype, ## select maptype
                   source = "google",
                   zoom = zoom) ## zoom, must be a whole number
  p <- ggmap::ggmap(gmap)
  p + ggplot2::geom_point(data = subset(site_data, include == TRUE), ggplot2::aes(longitude, latitude), pch=21, colour = "black", fill = "yellow") +
    ggplot2::geom_path(data=detection_data, ggplot2::aes(lon, lat, group=fullID, col = fullID)) +
    ggplot2::labs(x = "Longitude", y = "Latitude") + ggplot2::theme_bw()
}
