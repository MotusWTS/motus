#' Map of tag routes and sites coloured by id
#'
#' Google map of routes of Motus tag detections coloured by ID.  User defines a
#' date range to show points for receivers that were operational at some point
#' during the date range.
#'
#' @param zoom Integer. Override the calcualted zoom level to increase or
#'   decrease the resolution of the map tiles.
#' @param maptype Character. Map tiles to use. Must be one of `rosm::osm.types()`, 
#'   such as `osm`, `stamenbw`, etc. Most map tiles require attribution for 
#'   publication, see details.
#' @param start_date Character. Optional start date for routes. 
#' @param end_date Character. Optional end date for routes. 
#' @param lim_lat Numeric vector. Optional latitudinal plot limits.
#' @param lim_lon Numeric vector. Optional longitudinal plot limits.
#' @param lat Defunct
#' @param lon Defunct
#' @param recvStart Defunct
#' @param recvEnd Defunct
#' 
#' @inheritParams args
#' 
#' @details By default this function uses OSM maps (Open Street Map). OSM and
#'   many other map tiles are released under specific licences, which generally
#'   require that you give attribution at a minimum. See
#'   [OSM](https://www.openstreetmap.org/copyright) for more details on their
#'   tiles, but remember to check what other groups require if you use their
#'   tiles.
#' 
#' @export
#'
#' @examplesIf interactive()
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#' 
#' # Plot route map of all detection data, with "osm" maptype, and receivers
#' # active between 2016-01-01 and 2017-01-01
#' plotRouteMap(sql_motus, start_date = "2016-01-01", end_date = "2016-12-31")

plotRouteMap <- function(src, maptype = "osm", zoom = NULL, 
                         start_date = NULL, end_date = NULL,
                         lim_lat = NULL, lim_lon = NULL,
                         data, lat, lon, recvStart, recvEnd){
  
  # Deprecations
  if(!missing(recvStart) | !missing(recvEnd)) {
    warning("`recvStart` and `recvEnd` are deprecated in favour of `start_date` and `end_date`", call. = FALSE)
    start_date <- recvStart
    end_date <- recvEnd
  }
  if(!missing(data)) {
    warning("`data` is deprecated in favour of `sql`)", call. = FALSE)
    sql <- data
  }
  if(!missing(lat) | !missing(lon)) {
    warning("`lat` and `lon` are deprecated in favour of `lim_lat` and `lim_lon`", call. = FALSE)
    lim_lat <- lat
    lim_lon <- lon
  }
  
  
  if(!requireNamespace("ggspatial", quietly = TRUE)) {
    stop("Package 'ggspatial' required to plot route maps. ",
         "Use the code \"install.packages('ggspatial')\" to install.", call. = FALSE)
  }
  
  if(!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' required to plot route maps. ",
         "Use the code \"install.packages('sf')\" to install.", call. = FALSE)
  }

  if(!is.null(zoom) && !is.numeric(zoom)) stop('Numeric values required for `zoom`', call. = FALSE)
  if(!is.null(lim_lat) && !is.numeric(lim_lat)) stop('Numeric values required for `lim_lat`', call. = FALSE)
  if(!is.null(lim_lon) && !is.numeric(lim_lon)) stop('Numeric values required for `lim_lon`', call. = FALSE)

  site <- dplyr::tbl(src, "recvDeps")
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
  
  if(is.null(start_date)) start_date <- min(site$tsStart)
  if(is.null(end_date)) end_date <- max(site$tsEnd)
  date_range <- lubridate::interval(start_date, end_date) ## get time interval you are interested in

  data <- dplyr::tbl(src, "alltags")
  data <- dplyr::select(data, "motusTagID", "ts", "recvDeployLat", 
                        "recvDeployLon", "fullID", "recvDeployName", "speciesEN") %>% 
    dplyr::filter(!is.na(.data$recvDeployLat), !is.na(.data$recvDeployLon)) %>%
    dplyr::distinct() %>% 
    dplyr::collect() %>%
    dplyr::mutate(ts = lubridate::as_datetime(.data$ts, tz = "UTC")) %>%
    dplyr::arrange(.data$ts)
  
  ## Filter data sets to date range
  site <- dplyr::mutate(site, include = lubridate::int_overlaps(.data$interval, date_range)) %>%
    dplyr::select(-"interval") %>% # get around filter limitation
    dplyr::filter(.data$include)
  
  data <- dplyr::filter(data, lubridate::`%within%`(.data$ts, date_range))
  
  site_sf <- sf::st_as_sf(site, coords = c("longitude", "latitude"), crs = 4326)
  
  # Create *paths* from points (not just lines)
  data_sf <- points2Path(data)
  
  g <- ggplot2::ggplot(data = site_sf) +
    ggplot2::theme_bw() +
    ggspatial::annotation_map_tile(type = maptype, zoom = zoom) +
    ggplot2::geom_sf(shape = 21, colour = "black", fill = "yellow") +
    ggplot2::geom_sf(data = data_sf, ggplot2::aes(col = .data[["fullID"]])) +
    ggplot2::labs(x = "Longitude", y = "Latitude")
  
  if(!is.null(lim_lat) | !is.null(lim_lon)) {
    g <- g + ggplot2::coord_sf(xlim = lim_lon, ylim = lim_lat)
  }
  message("Remember to give proper attribution for your map tiles.")
  g
}

#' Convert points to path
#' 
#' Converts a data frame with a list of lat/lons to a spatial data frame with
#' MULTILINES defining paths by tag id. Useful for plotting with
#' `ggplot2::geom_sf()`. Will silently remove single points. 
#' 
#' @param by Character. Column defining the tag id over which to group points
#'   into paths. Defaults to "fullID".
#' 
#' @inheritParams args
#'
#' @return Spatial data frame with MULTILINE paths
#' @export
points2Path <- function(df, by = "fullID", 
                        lat = "recvDeployLat", lon = "recvDeployLon") {
  
  df %>%
    dplyr::select(dplyr::all_of(c(by, lat, lon))) %>%
    dplyr::filter(!(.data[[by]] == dplyr::lead(.data[[by]]) &
                      .data[[lat]] == dplyr::lead(.data[[lat]]) &
                      .data[[lon]] == dplyr::lead(.data[[lon]]))) %>%
    sf::st_as_sf(coords = c(lon, lat), crs = 4326) %>%
    dplyr::group_by(.data[[by]]) %>%
    dplyr::mutate(n = dplyr::n(),
                  geometry2 = dplyr::lead(.data[["geometry"]])) %>%
    dplyr::filter(.data[["n"]] > 1, !sf::st_is_empty(.data[["geometry2"]])) %>%
    dplyr::mutate(geometry3 = purrr::map2(.data[["geometry"]], .data[["geometry2"]], 
                                          ~ sf::st_cast(c(.x, .y), to = "LINESTRING")),
                  geometry3 = sf::st_as_sfc(.data[["geometry3"]], crs = 4326)) %>%
    sf::st_set_geometry(.[["geometry3"]]) %>%
    dplyr::summarize()
}
