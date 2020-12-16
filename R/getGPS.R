#' Get GPS variables
#' 
#' To improve speed, the `alltags` view doesn't include GPS-related variables
#' such as `gpsLat`, `gpsLon`, or `gpsAlt`. There is a `alltagsGPS` view that
#' does include GPS-related variables, but this will take time to load. This
#' function accepts a source and returns the GPS data associated with the
#' `hitID`s in the `alltags` view. Optionally, users can supply a
#' subset of the `alltags` view to return only GPS data associated with the
#' specific `hitID`s present in the subset.
#' 
#' @details 
#' There are three different methods for matching GPS data to `hitID`s
#' all related to timestamps (`ts`).
#' 
#'  1. `by = X` Where `X` is a duration in minutes. `ts` is converted to a
#'  specific time block of duration `X`. Median GPS lat/longs for the time block
#'  are returned, matching associated `hitID` time blocks.
#'  2. `by = "daily"` (the default). Similar to `by = X` except the duration is
#'  24hr.
#'  3. `by = "closest"` Individual GPS lat/lons are returned, matching the
#'  closest `hitID` timestamp. Use `cutoff` to specify the maximum
#'  allowable time between timestamps (defaults to none).
#'
#' @param src src_sqlite object representing the motus database 
#' @param data src_sqlite object or data.frame. Optional subset of the `alltags`
#'   view. Must have `ts`, `batchID` and `hitID` at the minimum.
#' @param by Numeric/Character. Either the time in minutes over which to join GPS
#'   locations to hits, or "daily" or "closest". To join GPS locations by daily
#'   time blocks or by the closest temporal match (see Details).
#' @param cutoff Numeric. The maximum allowable time in minutes between hit and
#'   GPS timestamps when matching hits to GPS with `by = 'closest'`. Defaults to
#'   `NULL` (no maximum).
#' @param keepAll Logical. Return all hits regardless of whether they have a GPS
#'   match? Defaults to FALSE.
#'
#' @return Data frame linking hitID to gpsLat, gpsLon and gpsAlt. 
#'   When `by = 'daily'` or `by = 'X'`, output includes:
#' 
#'   - `hitID` - the ID associated with the hit
#'   - `gpsLat` \ `gpsLon` \ `gpsAlt` - the median location calculated from the 
#'      available GPS points
#'   - `gpsTs_min` \ `gps_Ts_max` - the range of GPS timestamps associated with
#'      the GPS points binned
#'      
#'   When `by = 'closest'` or `by = 'X'`, output includes:
#' 
#'   - `hitID` - the ID associated with the hit
#'   - `gpsID` - the ID of the closest GPS point aligned with the `hitID`
#'   - `gpsLat` \ `gpsLon` \ `gpsAlt` - the location of the GPS point
#'   - `gpsTs` - the timestamp of the GPS point
#' 
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
#' # Match hits to GPS within 24hrs (daily) of each other
#' my_gps <- getGPS(sql.motus)
#' my_gps
#' 
#' # Note that the sample data doesn't have GPS hits so this will be an 
#' # empty data frame for project 176.
#' 
#' # Match hits to GPS within 15min of each other
#' my_gps <- getGPS(sql.motus, by = 15)
#' my_gps
#' 
#' # Match hits to GPS according to the closest timestamp
#' my_gps <- getGPS(sql.motus, by = "closest")
#' my_gps
#' 
#' # Match hits to GPS according to the closest timestamp, but limit to within
#' # 20min of each other
#' my_gps <- getGPS(sql.motus, by = "closest", cutoff = 20)
#' my_gps
#' 
#' # To return all hits, regardless of whether they match a GPS record
#' 
#' my_gps <- getGPS(sql.motus, keepAll = TRUE)
#' my_gps
#' 
#' # Alternatively, use the alltagsGPS view:
#' dplyr::tbl(sql.motus, "alltagsGPS")

getGPS <- function(src, data = NULL, by = "daily", cutoff = NULL, 
                   keepAll = FALSE) {
  if(!is.numeric(by) && !by %in% c("daily", "closest")) {
    stop("'by' must be either a number, 'daily' or 'closest'", call. = FALSE)
  }
  if(is.numeric(by) && by <= 0) {
    stop("'by' must be a number greater than zero", call. = FALSE)
  }
  if(!is.null(cutoff)) {
    if(by != "closest") message("'cutoff' is only applicable when by = 'closest'")
    if(!is.numeric(cutoff) || cutoff <= 0) {
      stop("'cutoff' must be a number greater than zero", call. = FALSE)  
    }
  }

  if(!"src_SQLiteConnection" %in% class(src)) {
    stop("'src' must be a SQLite connection to a .motus database (see ?tagme)", 
         call. = FALSE)
  }
  if(!"gps" %in% DBI::dbListTables(src$con)) {
    stop("'src' must contain a table 'gps'", call. = FALSE)
  }
  if(is.null(data) && !"alltags" %in% DBI::dbListTables(src$con)) {
    stop("'src' must contain the view 'alltags', unless 'data' is provided", 
         call. = FALSE)
  }
    
  
  gps <- prepGPS(src)
  if(nrow(gps) == 0 && !keepAll) return(gps)
  
  data <- prepData(src, data)
  if(nrow(gps) == 0 && keepAll) {
    return(dplyr::select(data, "hitID") %>%
             dplyr::collect() %>%
             dplyr::mutate(gpsLat = as.numeric(NA),
                           gpsLon = as.numeric(NA),
                           gpsAlt = as.numeric(NA)))
  }
  
  if(by == "closest") batches <- getBatches(src, cutoff)
  gps <- calcGPS(gps, data, by, cutoff = cutoff, batches = batches, keepAll = keepAll)
  
  dplyr::select(gps, "hitID", 
                tidyselect::any_of(c("gpsID")),
                tidyselect::any_of(c("gpsLat", "gpsLon", "gpsAlt")),
                tidyselect::any_of(c("gpsTs", "gpsTs_min", "gpsTs_max")))
}

prepGPS <- function(src) {
  gps <- dplyr::tbl(src, "gps") %>%
    dplyr::filter(.data$lat != 0, !is.na(.data$lat),
                  .data$lon != 0, !is.na(.data$lon)) %>%
    dplyr::select("gpsID", "batchID", "gpsTs" = "ts", 
                  "gpsLat" = "lat", "gpsLon" = "lon", "gpsAlt" = "alt") %>%
    dplyr::collect()
  
  if(nrow(gps) == 0) gps <- dplyr::tibble(hitID = 1L, gpsTs = 1.1,
                                          gpsLat = 1.1, gpsLon = 1.1, 
                                          gpsAlt = 1.1, .rows = 0)
  as.data.frame(gps)
}

prepData <- function(src, data = NULL) {

  if(is.null(data)) {
    data <- dplyr::tbl(src, "alltags")
  } else {
    # Check for correct columns
    if(!all(c("hitID", "batchID", "ts") %in% colnames(data))) {
      stop("'data' must be a subset of the 'alltags' view, containing ",
           "at least columns 'hitID', 'batchID' and 'ts'", call. = FALSE)
    }
    # Convert back to numeric in case user has changed it to date/time
    if(is.data.frame(data)) {
      if(lubridate::is.POSIXct(data$ts)) {
        data <- dplyr::mutate(data, ts = as.numeric(.data$ts))
      } else if(!is.numeric(data$ts)) {
        stop("'ts' column in 'data' must either be a numeric time stamp or ",
             "in POSIXct date/time format", call. = FALSE)
      }
    }
  }
  dplyr::select(data, "hitID", "batchID", "ts")
}

getBatches <- function(src, cutoff) {
  if(is.null(cutoff)) return(NULL)

  cutoff <- cutoff * 60
  
  batches <- dplyr::tbl(src$con, "batches") %>%
    dplyr::mutate(ts_min = .data$tsStart - cutoff,
                  ts_max = .data$tsEnd + cutoff) %>%
    dplyr::select("batchID", "tsStart", "tsEnd", "ts_min", "ts_max") %>%
    dplyr::collect()

  bchID <- batches$batchID
  Start <- batches$tsStart
  End <- batches$tsEnd
  min <- batches$ts_min
  max <- batches$ts_max
  
  batch_list <- vector(mode = "list", length = nrow(batches))
  for(b in seq_along(batches$batchID)) {
    batch_list[[b]] <- bchID[!(End <= min[b] | Start >= max[b])]
  }
  dplyr::mutate(batches, b = batch_list) %>%
      dplyr::select("batchID", "b")
}

calcGPS <- function(gps, data, by = "daily", cutoff = NULL, batches = NULL, keepAll = FALSE) {
  if(by == "closest") {
    if(!is.null(cutoff)) {
      cutoff <- cutoff * 60
    }
    
    gps_sub <- dplyr::collect(data)
    
    if(!is.null(batches)) {
      gps_sub <- gps_sub %>%
        dplyr::left_join(batches, by = "batchID") %>%
        dplyr::mutate(
          gpsID = purrr::map2_int(
            .data$b,
            .data$ts,
            ~getClosest(ts1 = gps$gpsTs[gps$batchID %in% .x], 
                        ts2 = .y, 
                        ids = gps$gpsID[gps$batchID %in% .x]))) %>%
        dplyr::select(-"b")
    } else {
      b <- unique(gps$batchID)
      gps_sub <- gps_sub %>%
        dplyr::mutate(
          gpsID = purrr::map_int(
            .data$ts,
            ~getClosest(ts1 = gps$gpsTs[gps$batchID %in% b], 
                        ts2 = ., 
                        ids = gps$gpsID[gps$batchID %in% b]))) 
    }
    gps <- dplyr::left_join(dplyr::select(gps_sub, -"batchID"),
                            dplyr::select(gps, -"batchID"),
                            by = "gpsID")
    
    if(is.null(cutoff)) {
      message("Max time difference between GPS location and hit is: ", 
              round(max(abs(gps$ts - gps$gpsTs), na.rm = TRUE)/60, 2), " min")
    } else {
      gps <- dplyr::mutate(gps, tsDiff = !is.na(.data$gpsTs) & 
                             abs(.data$ts - .data$gpsTs) > cutoff)
      gps[gps$tsDiff, c("gpsID", "gpsTs", "gpsLat", "gpsLon", "gpsAlt")] <- NA
      gps <- dplyr::select(gps, -"tsDiff")
    }
    
    if(!keepAll) gps <- dplyr::filter(gps, !is.na(.data$gpsID))
    
  } else {
    if(by == "daily") by <- 24 * 3600 else by <- by * 60
    
    data <- data %>%
      dplyr::mutate(timeBin = as.integer(.data$ts / by)) %>%
      dplyr::collect()
    
    gps_sub <- gps %>%
      dplyr::mutate(timeBin = as.integer(.data$gpsTs / by)) %>%
      dplyr::group_by(.data$timeBin) %>%
      dplyr::summarize(gpsLat = stats::median(.data$gpsLat),
                       gpsLon = stats::median(.data$gpsLon),
                       gpsAlt = stats::median(.data$gpsAlt),
                       gpsTs_min = min(.data$gpsTs),
                       gpsTs_max = max(.data$gpsTs)) %>%
      dplyr::ungroup()
    
    if(!keepAll) gps <- dplyr::inner_join(data, gps_sub, 
                                          by = "timeBin")
    
    if(keepAll) gps <- dplyr::left_join(data, gps_sub,
                                        by = "timeBin")
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
