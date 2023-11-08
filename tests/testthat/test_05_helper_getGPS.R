# Setup ------------------------------
expect_silent({
  tags <- withr::local_db_connection(tagmeSample("gps_sample.motus"))
  alltags <- dplyr::tbl(tags, "alltags")
  b <- 127792
  alltags1 <- alltags %>%
    dplyr::filter(.data$batchID == .env$b) %>%
    dplyr::collect()
})

# getGPS ------------------------------------------------------------------


test_that("getGPS() with no data", {
  skip_on_os("windows")
  
  tags <- withr::local_db_connection(tagmeSample())
  
  # No GPS data
  expect_silent(g <- getGPS(src = tags)) %>%
    expect_s3_class("data.frame")
  expect_equal(nrow(g), 0) # No GPS points
  
  # No GPS data but keepAll
  expect_silent(g <- getGPS(src = tags, keepAll = TRUE)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(g), 10000)
})

test_that("getGPS() date/time in ts", {
  
  d <- alltags %>%
    dplyr::collect() %>%
    dplyr::mutate(ts = lubridate::as_datetime(ts))
  
  expect_silent(g <- getGPS(src = tags, data = d)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(g), 0)
})


test_that("prepData() data.frame and src", {
  
  expect_silent(a <- prepData(tags, alltags)) %>%
    expect_s3_class("tbl_sql")
  
  expect_silent(a <- prepData(tags, dplyr::collect(alltags))) %>%
    expect_s3_class("data.frame")
  
  # errors
  expect_error(prepData(tags, dplyr::select(alltags, -hitID)),
               "'data' must be a subset of the 'alltags' view")
})

# library(ggplot2)
# ggplot(data = dplyr::tbl(tags, "batches") %>% dplyr::collect(), 
#        aes(xmin = tsStart, xmax = tsEnd, y = batchID)) + 
#   geom_errorbarh()

test_that("getBatches() returns batch subset", {
  
  expect_null(getBatches(tags, cutoff = NULL))
  expect_silent(b1 <- getBatches(tags, cutoff = 15)) %>%
    expect_s3_class("data.frame")
  expect_silent(b2 <- getBatches(tags, cutoff = 1000))
  
  expect_lt(sum(purrr::map_int(b1$b, length)), 
            sum(purrr::map_int(b2$b, length)))
  
  b <- dplyr::tbl(tags, "batches") %>% 
    dplyr::collect()
  
  # Expect that collected batches are within the range of the focal batch 
  # +/- the cutoff 
  
  diff_end <- b$tsEnd[4] - b$tsStart[b$batchID %in% b1$b[[4]]]
  diff_start <- b$tsStart[4] - b$tsEnd[b$batchID %in% b1$b[[4]]]
  
  expect_true(all((diff_end + 15*60) > 0  & (diff_start - 15*60) < 0))
  expect_false(all((diff_end + 1*60) > 0  & (diff_start - 1*60) < 0))
})

test_that("calcGPS() by = 'daily'", {
  
  # Daily Join
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags))) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true(all(abs(g$gpsTs_min - g$ts) <= 24*60*60))
  expect_true(all(abs(g$gpsTs_max - g$ts) <= 24*60*60))
  g <- dplyr::select(g, -hitID, -ts) %>% dplyr::distinct() %>% as.data.frame()
  
  expect_silent(getGPS(tags, by = "daily")) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt", 
                   "gpsTs_min", "gpsTs_max"))
})

test_that("calcGPS() by = 60", {
  
  # By = 60
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags), by = 60)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true(all(abs(g$gpsTs_min - g$ts) <= 60*60))
  expect_true(all(abs(g$gpsTs_max - g$ts) <= 60*60))
  
  gps <- dplyr::collect(dplyr::tbl(tags, "gps"))
  for(i in seq(1, nrow(g), length.out = 100)) {
    g1 <- gps %>%
      dplyr::filter(ts >= g$gpsTs_min[i],
                    ts <= g$gpsTs_max[i]) %>%
      dplyr::summarize(lat = median(lat, na.rm = TRUE),
                       lon = median(lon, na.rm = TRUE),
                       alt = median(alt, na.rm = TRUE))
    
    expect_equal(g$gpsLat[!!i], g1$lat)
    expect_equal(g$gpsLon[!!i], g1$lon)
    expect_equal(g$gpsAlt[!!i], g1$alt)
  }
  
  expect_silent(getGPS(tags, by = 60)) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs_min", "gpsTs_max"))
})

test_that("calcGPS() by = 120", {
  
  # By = 120 seconds
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags), by = 120/60)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_equal(g$gpsTs_min, g$gpsTs_max) # No medians
  expect_true(all(abs(g$gpsTs_min - g$ts) <= 120))
  expect_true(all(abs(g$gpsTs_max - g$ts) <= 120))
  g1 <- dplyr::left_join(
    dplyr::select(g, batchID, hitts = ts, ts = gpsTs_min, 
                  gpsLat, gpsLon, gpsAlt), 
    dplyr::collect(dplyr::tbl(tags, "gps")), by = c("ts", "batchID")) %>%
    dplyr::filter(!is.na(lat), !is.na(lon))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_true(all(abs(g1$hitts - g1$ts) <= 120))
  
  expect_silent(getGPS(tags, by = 120/60)) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt", 
                   "gpsTs_min", "gpsTs_max"))
})

test_that("calcGPS() by = 'closest'", {
  
  # By = "closest"
  expect_message(g <- calcGPS(prepGPS(tags), prepData(tags), by = "closest"),
                 "Max time difference")
  expect_s3_class(g, "data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true("gpsID" %in% names(g)) # exact match with gpsID, not range
  expect_false(all(abs(g$ts - g$gpsTs) <= 15*60, na.rm = TRUE)) # Expect long time between matches
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID, gpsTs,
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")),
                         by = "gpsID")
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_equal(g1$gpsTs, g1$ts)
  
  expect_message(g <- getGPS(tags, by = "closest"), "Max time difference")
  expect_named(g, c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
  
  # By = "closest", cutoff not NULL
  expect_silent(g <- calcGPS(prepGPS(tags), 
                             prepData(tags), 
                             batches = getBatches(tags, cutoff = 10),
                             by = "closest",
                             cutoff = 10))
  expect_s3_class(g, "data.frame")
  expect_true(all(abs(g$ts - g$gpsTs) <= 10*60, na.rm = TRUE))
  
  expect_silent(g <- getGPS(tags, by = "closest", cutoff = 10))
  expect_named(g, c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
})

test_that("getGPS errors", {
  tags <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_error(getGPS(tags))
  
  tags <- withr::local_db_connection(tagmeSample("gps_sample.motus"))
  expect_error(getGPS(tags, by = "daaaaily"))
  expect_error(getGPS(tags, by = 0))
  expect_error(getGPS(tags, by = -100))
})

test_that("calcGPS() - Daily", {

  # Daily Join
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags, alltags1))) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_true(all(g$hitID %in% alltags1$hitID))
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true(all(abs(g$gpsTs_min - g$ts) <= 24*60*60)) # Daily diff
  expect_true(all(abs(g$gpsTs_max - g$ts) <= 24*60*60)) # Daily diff
  
  expect_silent(getGPS(tags, by = "daily")) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs_min", "gpsTs_max"))
})

test_that("calcGPS() - 60min", {
  # By = 60
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags, alltags1), by = 60)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_true(all(g$hitID %in% alltags1$hitID))
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true(all(abs(g$gpsTs_min - g$ts) <= 60*60)) # Hourly diff
  expect_true(all(abs(g$gpsTs_max - g$ts) <= 60*60)) # Hourly diff
  
  gps <- dplyr::collect(dplyr::tbl(tags, "gps"))
  for(i in seq(1, nrow(g), 50)) {
    g1 <- gps %>%
      dplyr::filter(ts >= g$gpsTs_min[i],
                    ts <= g$gpsTs_max[i]) %>%
      dplyr::summarize(lat = median(lat, na.rm = TRUE),
                       lon = median(lon, na.rm = TRUE),
                       alt = median(alt, na.rm = TRUE))
    
    expect_equal(g$gpsLat[!!i], g1$lat)
    expect_equal(g$gpsLon[!!i], g1$lon)
    expect_equal(g$gpsAlt[!!i], g1$alt)
  }
  
  expect_silent(getGPS(tags, by = 60)) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs_min", "gpsTs_max"))
})

test_that("calcGPS() - closest", {
  
  # By = "closest"
  expect_message(g <- calcGPS(prepGPS(tags), prepData(tags, alltags1), by = "closest"),
                 "Max time difference")
  expect_s3_class(g, "data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_true(all(g$hitID %in% alltags1$hitID))
  expect_true(all(alltags1$hitID %in% g$hitID))
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true("gpsID" %in% names(g)) # exact match with gpsID, not range
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID,
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")),
                         by = "gpsID")
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  
  expect_message(g <- getGPS(tags, by = "closest"), "Max time difference")
  expect_named(g, c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
  
  # By = "closest", cutoff not NULL
  expect_silent(g <- calcGPS(prepGPS(tags), 
                             prepData(tags, alltags1), 
                             batches = getBatches(tags, cutoff = 10),
                             by = "closest",
                             cutoff = 10)) %>%
    expect_s3_class("data.frame")
  expect_true(all(abs(g$ts - g$gpsTs) <= 10*60, na.rm = TRUE))
  
  expect_silent(g <- getGPS(tags, by = "closest", cutoff = 10))
  expect_named(g, c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
})   


test_that("calcGPS() keepAll = TRUE", {
  
  # By = 5 seconds
  expect_silent(g1 <- calcGPS(prepGPS(tags), prepData(tags), by = 120/60)) %>%
    expect_s3_class("data.frame")
  expect_silent(g2 <- calcGPS(prepGPS(tags), prepData(tags), by = 120/60,
                              keepAll = TRUE)) %>%
    expect_s3_class("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
  
  # By = "closest"
  expect_silent(g1 <- calcGPS(prepGPS(tags), prepData(tags), by = "closest",
                              cutoff = 2)) %>%
    expect_s3_class("data.frame")
  expect_silent(g2 <- calcGPS(prepGPS(tags), prepData(tags), by = "closest", 
                              cutoff = 2, keepAll = TRUE)) %>%
    expect_s3_class("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
})   

