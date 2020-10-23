#' Map of tag routes and sites coloured by id
#'
#' Google map of routes of Motus tag detections coloured by ID.  User defines a date range to show
#' points for receivers that were operational at some point during the date range.
#'
#' @param data a .motus sql file
#' @param zoom integer.  Values between 3 and 21, 3 being continent level, 10 being city-scale
#' @param lat numeric vector. Top and bottom latitude bounds. If NULL (default)
#'   this is calculated from the data
#' @param lon  numeric vector. Left and right longitude bounds. If NULL
#'   (default) this is calculated from the data
#' @param maptype map type to display, can be: "terrain" , "toner",
#'   "watercolor", or any other option available to
#'   \code{\link[ggmap]{get_stamenmap}()}.
#' @param recvStart start date for date range of active receivers. If NULL uses
#'   the full data range
#' @param recvEnd end date for date range of active receivers. If NULL uses the
#'   full data range
#' 
#' @details By default this function uses Stamen maps
#' 
#' @export
#'
#' @examples
#' # You must use a .motus sql file, instructions to load using tagme() are
#' # below
#' 
#' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#' 
#' # Plot routemap of all detection data, with "terrain" maptype, and receivers
#' # active between 2016-01-01 and 2017-01-01
#' plotRouteMap(sql.motus, recvStart = "2016-01-01", recvEnd = "2016-12-31")

plotRouteMap <- function(data, zoom = 3, lat = NULL, lon = NULL,
                         maptype = "terrain", recvStart = NULL, recvEnd = NULL){
  
  if(!requireNamespace("ggmap", quietly = TRUE)) {
    stop("Package 'ggmap' required to plot route maps. ",
         "Use the code \"install.packages('ggmap')\" to install.", call. = FALSE)
  } else if(utils::packageVersion("ggmap") < "3.0.0") {
    stop("Package 'ggmap' requires version 3.0.0 to plot route maps. ",
         "Use the code \"update.packages('ggmap')\" to update to the ",
         "most recent version.", call. = FALSE)
  }
  
  if(class(zoom) != "numeric") stop('Numeric value between 3 and 21 required for "zoom"', call. = FALSE)
  if(class(lat) %in% c(NULL, "numeric")) stop('Numeric values required for "lat"', call. = FALSE)
  if(class(lon) %in% c(NULL, "numeric")) stop('Numeric values required for "lon"', call. = FALSE)

  site <- dplyr::tbl(data, "recvDeps")
  site <- site %>% 
    dplyr::select("name", "latitude", "longitude", "tsStart", "tsEnd") %>% 
    dplyr::distinct() %>% 
    dplyr::filter(!is.na(.data$latitude), !is.na(.data$longitude)) %>% # Omit missing lat/lon
    dplyr::collect() %>%
    dplyr::mutate(tsStart = lubridate::as_datetime(.data$tsStart, tz = "UTC"),
                  tsEnd = lubridate::as_datetime(.data$tsEnd, tz = "UTC"),
                  ## for sites with no end date, make an end date a year from now
                  tsEnd = lubridate::as_datetime(
                    dplyr::if_else(is.na(.data$tsEnd),
                                   lubridate::as_datetime(format(Sys.time(), "%Y-%m-%d %H:%M:%S")) + lubridate::dyears(1),
                                   .data$tsEnd), tz = "UTC"),
                  interval = lubridate::interval(.data$tsStart, .data$tsEnd))
  
  if(is.null(recvStart)) recvStart <- min(site$tsStart)
  if(is.null(recvEnd)) recvEnd <- max(site$tsEnd)
  dateRange <- lubridate::interval(recvStart, recvEnd) ## get time interval you are interested in

  data <- dplyr::tbl(data, "alltags")
  data <- dplyr::select(data, "motusTagID", "ts", "recvDeployLat", 
                        "recvDeployLon", "fullID", "recvDeployName", "speciesEN") %>% 
    dplyr::filter(!is.na(.data$recvDeployLat), !is.na(.data$recvDeployLon)) %>%
    dplyr::distinct() %>% 
    dplyr::collect() %>%
    dplyr::mutate(ts = lubridate::as_datetime(.data$ts, tz = "UTC")) %>%
    dplyr::arrange(.data$ts)
  
  ## Filter data sets to date range
  site <- dplyr::mutate(site, include = lubridate::int_overlaps(.data$interval, dateRange)) %>%
    dplyr::select(-"interval") %>% # get around filter limitation
    dplyr::filter(.data$include)
  
  data <- dplyr::filter(data, lubridate::`%within%`(.data$ts, dateRange))
  
  # In case user supplies wrong order
  lon <- sort(lon)
  lat <- sort(lat)

  # Calculate bounds from data if NULL
  if(any(is.null(lon))) {
    lon <- c(min(c(data$recvDeployLon, site$longitude)), 
             max(c(data$recvDeployLon, site$longitude)))
    # Add a bit of wiggle room to the edges
    lon[1] <- lon[1] - abs(lon[2]-lon[1])*0.05
    lon[2] <- lon[2] + abs(lon[2]-lon[1])*0.05
  }
    
  if(any(is.null(lat))) {
    lat <- c(min(c(data$recvDeployLat, site$latitude)),
             max(c(data$recvDeployLat, site$latitude)))
    # Add a bit of wiggle room to the edges
    lat[1] <- lat[1] - abs(lat[2]-lat[1])*0.05
    lat[2] <- lat[2] + abs(lat[2]-lat[1])*0.05 
  }
  
  gmap <-  ggmap::get_stamenmap(bbox = c(left = lon[1], right = lon[2],
                                         bottom = lat[1], top = lat[2]),
                                zoom = zoom,
                                maptype = maptype)
  ggmap::ggmap(gmap) +
    ggplot2::geom_point(data = site, ggplot2::aes_string(x = "longitude", y = "latitude"), 
                        shape = 21, colour = "black", fill = "yellow") +
    ggplot2::geom_path(data = data, 
                       ggplot2::aes_string(x = "recvDeployLon", y = "recvDeployLat", 
                                    group = "fullID", col = "fullID")) +
    ggplot2::labs(x = "Longitude", y = "Latitude") + 
    ggplot2::theme_bw()
}
