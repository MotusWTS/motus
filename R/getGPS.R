#' Get GPS variables
#' 
#' To improve speed, the `alltags` view doesn't include GPS-related variables
#' such as `gpsLat`, `gpsLon`, or `gpsAlt`. There is a `alltagsGPS` view that
#' does include GPS-related variables, but this will take time to load. This
#' function accepts a source and returns the GPS data associated with the
#' `bachID`/`hitID` combos in the `alltags` view. Optionally, users can supply a
#' subset of the `alltags` view to return only GPS data associated with the
#' specific `batchID`/`hitID` combos present in the subset.
#' 
#' @details 
#' There are three different methods for matching GPS data to `bachID`/`hitID`
#' combos, all related to timestamps (`ts`).
#' 
#'  1. `by = X` Where `X` is a duration in minutes. `ts` is converted to a
#'  specific timeblock of duration `X`. Median GPS lat/longs for the timeblock
#'  are returned, matching associated `batchID`/`hitID` timeblocks.
#'  2. `by = "daily"` (the default). Similar to `by = X` except the duration is
#'  24hr.
#'  3. `by = "closest"` Individual GPS lat/lons are returned, matching the
#'  closest `batchID`/`hitID` timestamp.
#'
#' @param src src_sqlite object representing the database 
#' @param alltags src_sqlite object or data.frame Optional subset of the alltags
#'   view. Must have `ts`, `hitID` and `batchID` at the minimum.
#' @param by Numeric/Character Either the time in minutes overwhich to join GPS
#'   locations to hits, or "daily" or "closest". To join GPS locations by daily
#'   timeblocks or by the closest temporal match (see Details).
#' @param keepAll Logical Return all hits regardless of whether they have a GPS
#'   match? Defaults to FALSE.
#'
#' @return Data frame linking hitID to gpsLat, gpsLon and gpsAlt
#' @export
#'
#' @examples
#' 
#' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#' 
#' my_gps <- getGPS(sql.motus)
#' my_gps
#' 
#' # Note that the sample data doesn't have GPS hits so this will be an 
#' # empty data frame for project 176.
#' 
#' # To return all hits, regardless of whether they match a GPS record
#' 
#' my_gps <- getGPS(sql.motus, keepAll = TRUE)
#' my_gps
#' 
#' # Alternatively, use the alltagsGPS view:
#' dplyr::tbl(sql.motus, "alltagsGPS")

getGPS <- function(src, alltags = NULL, by = "daily", keepAll = FALSE) {
  if(!is.numeric(by) && !by %in% c("daily", "closest")) {
    stop("'by' must be either a number, 'daily' or 'closest'", call. = FALSE)
  }
  if(is.numeric(by) && by <= 0) {
    stop("'by' must be a number greater than zero", call. = FALSE)
  }
  gps <- prepGPS(src)
  if(nrow(gps) == 0 && !keepAll) return(gps)
  
  alltags <- prepAlltags(src, alltags)
  if(nrow(gps) == 0 && keepAll) {
    return(dplyr::select(alltags, "hitID") %>%
             dplyr::collect() %>%
             dplyr::mutate(gpsLat = as.numeric(NA),
                           gpsLon = as.numeric(NA),
                           gpsAlt = as.numeric(NA)))
  }
  
  gps <- calcGPS(gps, alltags, by, keepAll = keepAll)
  
  dplyr::select(gps, "hitID", "gpsLat", "gpsLon", "gpsAlt")
}

prepGPS <- function(src) {
  gps <- dplyr::tbl(src, "gps") %>%
    dplyr::filter(.data$lat != 0, !is.na(.data$lat),
                  .data$lon != 0, !is.na(.data$lon)) %>%
    dplyr::select("gpsID", "batchID", "ts", 
                  "gpsLat" = "lat", "gpsLon" = "lon", "gpsAlt" = "alt") %>%
    dplyr::collect()
  
  if(nrow(gps) == 0) gps <- dplyr::tibble(hitID = 1L, gpsLat = 1.1, 
                                          gpsLon = 1.1, gpsAlt = 1.1, 
                                          .rows = 0)
  as.data.frame(gps)
}

prepAlltags <- function(src, alltags = NULL) {
  if(is.null(alltags)) {
    alltags <- dplyr::tbl(src, "alltags")
  } else {
    # Check for correct columns
    if(!all(c("hitID", "batchID", "ts") %in% colnames(alltags))) {
      stop("'alltags' must be a subset of the 'alltags' view, containing ",
           "at least columns 'hitID', 'batchID' and 'ts'", call. = FALSE)
    }
  }
  dplyr::select(alltags, "hitID", "batchID", "ts")
}

calcGPS <- function(gps, alltags, by = "daily", keepAll = FALSE) {
  if(by == "closest") {
    gps_sub <- dplyr::collect(alltags) %>%
      dplyr::mutate(
        gpsID = purrr::map2_int(
          .data$batchID, .data$ts, 
          ~getClosest(ts1 = gps$ts[gps$batchID == .x], 
                      ts2 = .y, 
                      ids = gps$gpsID[gps$batchID == .x])))
    
    if(!keepAll) gps <- dplyr::inner_join(gps_sub, 
                                          dplyr::rename(gps, "gpsts" = "ts"), 
                                          by = c("batchID", "gpsID"))
    if(keepAll) gps <- dplyr::left_join(gps_sub, 
                                        dplyr::rename(gps, "gpsts" = "ts"), 
                                        by = c("batchID", "gpsID"))
    
    message("Max time difference between GPS location and hit is: ", 
            round(max(abs(gps$ts - gps$gpsts), na.rm = TRUE)/60, 2), " min")
  } else {
    if(by == "daily") by <- 24 * 3600 else by <- by * 60
    
    alltags <- alltags %>%
      dplyr::mutate(timeBin = as.integer(.data$ts / by)) %>%
      dplyr::collect()
    
    gps_sub <- gps %>%
      dplyr::mutate(timeBin = as.integer(.data$ts / by)) %>%
      dplyr::group_by(.data$batchID, .data$timeBin) %>%
      dplyr::summarize(gpsID_min = min(.data$gpsID),
                       gpsID_max = max(.data$gpsID),
                       gpsLat = stats::median(.data$gpsLat),
                       gpsLon = stats::median(.data$gpsLon),
                       gpsAlt = stats::median(.data$gpsAlt)) %>%
      dplyr::ungroup()
    
    if(!keepAll) gps <- dplyr::inner_join(alltags, gps_sub, 
                                          by = c("batchID", "timeBin"))
    
    if(keepAll) gps <- dplyr::left_join(alltags, gps_sub,
                                        by = c("batchID", "timeBin"))
  }
  gps
}

getClosest <- function(ts1, ts2, ids) {
  
  if(length(ts1) == 0) {
    return(as.integer(NA))
  } else {
    return(ids[which.min(abs(ts1 - ts2))])
  }
}