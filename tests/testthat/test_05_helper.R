teardown({
  unlink("project-176.motus")
  unlink("gps_sample.motus")
})


# filterByActivity --------------------------------------------------------
context("filterByActivity")
test_that("filterByActivity filters as expected", {
  expect_silent(
    shorebirds_sql <- tagme(176, update = FALSE, 
                            dir = system.file("extdata", package = "motus")))
  
  expect_silent(a <- filterByActivity(shorebirds_sql, return = "all")) %>%
    expect_is("tbl")
  expect_silent(g <- filterByActivity(shorebirds_sql)) %>%
    expect_is("tbl")
  expect_silent(b <- filterByActivity(shorebirds_sql, return = "bad")) %>%
    expect_is("tbl")
  
  # 'good' and 'bad' should be subsets of 'all'
  expect_equal(nrow(a <- dplyr::collect(a)), 
               nrow(g <- dplyr::collect(g)) + nrow(b <- dplyr::collect(b)))
                 
  expect_true(dplyr::all_equal(dplyr::filter(a, probability == 1), g))
  expect_true(dplyr::all_equal(dplyr::filter(a, probability == 0), b))
  
  # Matches motusFilter results
  runs <- dplyr::tbl(shorebirds_sql, "runs") %>%
    dplyr::select(runID, batchID = batchIDbegin, 
                  runLen = len, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect() %>%
    dplyr::filter(runID != 2358172, batchID != 1991040)  #Extra filtering applied
  
  a <- a %>%
    dplyr::mutate(motusFilter = as.numeric(probability)) %>%
    dplyr::select(runID, batchID, runLen, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect() %>%
    dplyr::filter(runID != 2358172, batchID != 1991040) #Extra filtering applied
  
  expect_true(dplyr::all_equal(runs, a))
})

test_that("Good/Bad runs change depending on parameters", {
  expect_silent(
    shorebirds_sql <- tagme(176, update = FALSE, 
                            dir = system.file("extdata", package = "motus")))
  
  # Expect run lengths to change if adjust the parameters
  expect_silent(a <- filterByActivity(shorebirds_sql, minLen = 10, maxLen = 15, return = "all"))
  expect_equal(dplyr::filter(a, runLen <= 10) %>%
                 dplyr::summarize(probability = sum(probability, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  expect_equal(dplyr::filter(a, runLen >= 15) %>%
                 dplyr::summarize(probability = sum(probability == 0, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  

  expect_silent(a <- filterByActivity(shorebirds_sql, minLen = 2, maxLen = 5, return = "all"))
  expect_equal(dplyr::filter(a, runLen <= 2) %>%
                 dplyr::summarize(probability = sum(probability, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  expect_equal(dplyr::filter(a, runLen >= 5) %>%
                 dplyr::summarize(probability = sum(probability == 0, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
})

test_that("Empty activity table stops", {
  file.copy(system.file("extdata", "project-176.motus", package = "motus"),
            ".")
  tags <- tagme(176, update = FALSE)
  
  # Empty activity
  DBI::dbExecute(tags$con, "DELETE FROM activity")
  expect_error(a <- filterByActivity(tags, return = "all"),
               "'activity' table is empty, cannot filter by activity")
  
  # No activity
  DBI::dbRemoveTable(tags$con, "activity")
  expect_error(a <- filterByActivity(tags, return = "all"),
               "'src' must contain at least tables 'activity', 'alltags',")
  
  DBI::dbDisconnect(tags$con)
})


# getGPS ------------------------------------------------------------------
context("getGPS")
test_that("getGPS() runs as expected with no data", {
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  
  # No GPS data
  tags <- tagme(projRecv = 176, new = FALSE, update = FALSE)
  expect_silent(g <- getGPS(src = tags)) %>%
    expect_is("data.frame")
  expect_equal(nrow(g), 0) # No GPS points
  
  # No GPS data but keepAll
  expect_silent(g <- getGPS(src = tags, keepAll = TRUE)) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 10000)
  
  unlink("project-176.motus")
})

test_that("getGPS() handels date/time in ts gracefully", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- tagme("gps_sample", new = FALSE, update = FALSE)
  d <- dplyr::tbl(tags, "alltags") %>%
    dplyr::collect() %>%
    dplyr::mutate(ts = lubridate::as_datetime(ts))
  
  expect_silent(g <- getGPS(src = tags, data = d)) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0)
  
  unlink("gps_sample.motus")
})


test_that("prepData() handles both data.frame and src", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  tags <- DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus")
  alltags <- dplyr::tbl(tags, "alltags")
  
  expect_silent(a <- prepData(tags, alltags)) %>%
    expect_is("tbl_sql")
  
  expect_silent(a <- prepData(tags, dplyr::collect(alltags))) %>%
    expect_is("data.frame")
  
  # errors
  expect_error(prepData(tags, dplyr::select(alltags, -hitID)),
               "'data' must be a subset of the 'alltags' view")
  
  DBI::dbDisconnect(tags)
  unlink("gps_sample.motus")
})

# library(ggplot2)
# ggplot(data = dplyr::tbl(tags, "batches") %>% dplyr::collect(), 
#        aes(xmin = tsStart, xmax = tsEnd, y = batchID)) + 
#   geom_errorbarh()

test_that("getBatches() returns batch subset", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")

  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), 
                                               "gps_sample.motus"))
  
  expect_null(getBatches(tags, cutoff = NULL))
  expect_silent(b1 <- getBatches(tags, cutoff = 15)) %>%
    expect_is("data.frame")
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
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})

test_that("calcGPS() matches GPS by = 'daily'", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), 
                                               "gps_sample.motus"))
  
  # Daily Join
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags))) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true(all(abs(g$gpsTs_min - g$ts) <= 24*60*60))
  expect_true(all(abs(g$gpsTs_max - g$ts) <= 24*60*60))
  g <- dplyr::select(g, -hitID, -ts) %>% dplyr::distinct() %>% as.data.frame()
  
  expect_silent(getGPS(tags, by = "daily")) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs_min", "gpsTs_max"))
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})
  
test_that("calcGPS() matches GPS by = 60", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus"))
  
  # By = 60
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags), by = 60)) %>%
    expect_is("data.frame")
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
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})

test_that("calcGPS() matches GPS by = 120", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), 
                                               "gps_sample.motus"))
  
  # By = 120 seconds
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags), by = 120/60)) %>%
    expect_is("data.frame")
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
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})

test_that("calcGPS() matches GPS by = 'closest'", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- dbplyr::src_dbi(DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus"))
  
  # By = "closest"
  expect_message(g <- calcGPS(prepGPS(tags), prepData(tags), by = "closest"),
                 "Max time difference") %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true("gpsID" %in% names(g)) # exact match with gpsID, not range
  expect_false(all(abs(g$ts - g$gpsTs) <= 15*60, na.rm = TRUE)) # Expect long time between matches
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID, gpsTs,
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_equal(g1$gpsTs, g1$ts)

  expect_message(getGPS(tags, by = "closest"), "Max time difference") %>%
    expect_named(c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
  
  # By = "closest", cutoff not NULL
  expect_silent(g <- calcGPS(prepGPS(tags), 
                             prepData(tags), 
                             batches = getBatches(tags, cutoff = 10),
                             by = "closest",
                             cutoff = 10)) %>%
    expect_is("data.frame")
  expect_true(all(abs(g$ts - g$gpsTs) <= 10*60, na.rm = TRUE))
  
  expect_silent(getGPS(tags, by = "closest", cutoff = 10)) %>%
    expect_named(c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})   

test_that("getGPS errors", {
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), 
                                               ":memory:"))
  expect_error(getGPS(tags))
  DBI::dbDisconnect(tags$con)

  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus"))
  expect_error(getGPS(tags, by = "daaaaily"))
  expect_error(getGPS(tags, by = 0))
  expect_error(getGPS(tags, by = -100))
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})

test_that("calcGPS() matches GPS with subset - Daily", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus"))
  alltags <- dplyr::tbl(tags, "alltags") %>%
    dplyr::filter(batchID == batchID[1]) %>%
    dplyr::collect()
  
  # Daily Join
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags, alltags))) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_true(all(g$hitID %in% alltags$hitID))
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true(all(abs(g$gpsTs_min - g$ts) <= 24*60*60)) # Daily diff
  expect_true(all(abs(g$gpsTs_max - g$ts) <= 24*60*60)) # Daily diff
  
  expect_silent(getGPS(tags, by = "daily")) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs_min", "gpsTs_max"))
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})

test_that("calcGPS() matches GPS with subset - 60min", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus"))
  alltags <- dplyr::tbl(tags, "alltags") %>%
    dplyr::filter(batchID == batchID[1]) %>%
    dplyr::collect()
  
  # By = 60
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags, alltags), by = 60)) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_true(all(g$hitID %in% alltags$hitID))
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
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})

test_that("calcGPS() matches GPS with subset - closest", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus"))
  alltags <- dplyr::tbl(tags, "alltags") %>%
    dplyr::filter(batchID == batchID[1]) %>%
    dplyr::collect()
  
  # By = "closest"
  expect_message(g <- calcGPS(prepGPS(tags), prepData(tags, alltags), by = "closest"),
                 "Max time difference") %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # There are GPS points
  expect_true(all(g$hitID %in% alltags$hitID))
  expect_true(all(alltags$hitID %in% g$hitID))
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true("gpsID" %in% names(g)) # exact match with gpsID, not range
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID,
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  
  expect_message(getGPS(tags, by = "closest"), "Max time difference") %>%
    expect_named(c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
  
  # By = "closest", cutoff not NULL
  expect_silent(g <- calcGPS(prepGPS(tags), 
                             prepData(tags, alltags), 
                             batches = getBatches(tags, cutoff = 10),
                             by = "closest",
                             cutoff = 10)) %>%
    expect_is("data.frame")
  expect_true(all(abs(g$ts - g$gpsTs) <= 10*60, na.rm = TRUE))
  
  expect_silent(getGPS(tags, by = "closest", cutoff = 10)) %>%
    expect_named(c("hitID", "gpsID", "gpsLat", "gpsLon", "gpsAlt", "gpsTs"))
  
  
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})   


test_that("calcGPS() keepAll = TRUE", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), 
                                               "gps_sample.motus"))

  # By = 5 seconds
  expect_silent(g1 <- calcGPS(prepGPS(tags), prepData(tags), by = 120/60)) %>%
    expect_is("data.frame")
  expect_silent(g2 <- calcGPS(prepGPS(tags), prepData(tags), by = 120/60,
                              keepAll = TRUE)) %>%
    expect_is("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
  
  # By = "closest"
  expect_silent(g1 <- calcGPS(prepGPS(tags), prepData(tags), by = "closest",
                               cutoff = 2)) %>%
    expect_is("data.frame")
  expect_silent(g2 <- calcGPS(prepGPS(tags), prepData(tags), by = "closest", 
                               cutoff = 2, keepAll = TRUE)) %>%
    expect_is("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
  
  DBI::dbDisconnect(tags$con)
  unlink("gps_sample.motus")
})   


# sunRiseSet --------------------------------------------------------------

test_that("sunRiseSet() returns sunset times", {
  
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), 
            to = ".")
  t <- tagme(176, update = FALSE, new = FALSE)
  
  expect_message(s1 <- sunRiseSet(t), "'data' is a complete motus data base") %>%
    expect_s3_class("data.frame")
  expect_silent(s2 <- sunRiseSet(dplyr::tbl(t, "alltags"))) %>%
    expect_s3_class("data.frame")
  
  expect_equal(s1, s2)
  
  expect_true(all(c("sunrise", "sunset") %in% names(s1)))
  expect_s3_class(s1$sunrise, "POSIXct")
  expect_s3_class(s1$sunset, "POSIXct")
  
  # Only added sunrise and sunset
  expect_equal(dplyr::tbl(t$con, "alltags") %>% 
                 dplyr::collect() %>%
                 dplyr::arrange(tsCorrected, hitID, runID, batchID), 
               dplyr::select(s1, -"sunrise", -"sunset") %>%
                 dplyr::arrange(tsCorrected, hitID, runID, batchID))
  
  # If missing lat/lon missing sunrise
  expect_equal(sum(is.na(s1$sunrise)), 
               sum(is.na(s1$recvDeployLat) | is.na(s1$recvDeployLon)))
  expect_equal(sum(is.na(s1$sunset)), 
               sum(is.na(s1$recvDeployLat) | is.na(s1$recvDeployLon)))
  
  s1_sub <- dplyr::filter(s1, !is.na(sunrise), !is.na(sunset)) %>%
    dplyr::mutate(ts = lubridate::as_datetime(ts, tz = "UTC"))
  expect_true(all(abs(difftime(s1_sub$ts, s1_sub$sunrise, units = "hours")) < 24))
  expect_true(all(abs(difftime(s1_sub$ts, s1_sub$sunset, units = "hours")) < 24))

  # Require lutz
  mockery::stub(sunRiseSet, "requireNamespace", FALSE)
  expect_error(sunRiseSet(t), "The package 'lutz' is required") %>%
    expect_message("'data' is a complete")
  
  unlink("project-176.motus")
})


# deprecateBatches() -------------------------------------


test_that("deprecated batches are removed from tables - sample", {
  sample_auth()
  unlink("project-176.motus")
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), 
            to = ".")
  t <- tagme(176, update = FALSE, new = FALSE)
  
  # Deprecated batches listed, but not removed to start
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 0))
  
  # Make fake deprecated batches
  d <- dep$batchID
  
  # To start, expect deprecated batches in data
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_gt(., 0)
  
  for(i in DBI::dbListTables(t$con)) {
    if("batchID" %in% DBI::dbListFields(t$con, i) &
       DBI::dbExecute(t$con, glue::glue("SELECT * FROM {i} LIMIT 1")) > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_gt(., 0)
    }
  }
  
  # Deprecate batches
  expect_message(removeDeprecated(t, ask = FALSE))
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 1))
  
  # With deprecated, expect deprecated batches removed
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% !!d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_equal(., 0)
  
  for(i in DBI::dbListTables(t$con)) {
    if("batchID" %in% DBI::dbListFields(t$con, i) &
       DBI::dbExecute(t$con, glue::glue("SELECT * FROM {i} LIMIT 1")) > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_equal(., 0)
    }
  }
  
  unlink("project-176.motus")  
})


test_that("deprecated batches are removed from tables project 1", {
  skip_if_no_auth()
  
  # Deprecated batches listed, but not removed to start
  unlink("project-1.motus")
  expect_message(t <- tagme(1, new = TRUE, update = TRUE))
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 0))
  
  # Make fake deprecated batches
  d <- c(4597, 101694)
  data.frame(batchID = d, batchFilter = 4, removed = 0) %>%
    DBI::dbWriteTable(t$con, "deprecated", ., append = TRUE)
  
  # To start, expect deprecated batches in data
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_gt(., 0)
  
  for(i in DBI::dbListTables(t$con)) {
    if("batchID" %in% DBI::dbListFields(t$con, i) &
       DBI::dbExecute(t$con, glue::glue("SELECT * FROM {i} LIMIT 1")) > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_gt(., 0)
    }
  }

  # Deprecate batches
  expect_message(removeDeprecated(t, ask = FALSE))
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 1))

  # With deprecated, expect deprecated batches removed
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% !!d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_equal(., 0)
  
  for(i in DBI::dbListTables(t$con)) {
    if("batchID" %in% DBI::dbListFields(t$con, i) &
       DBI::dbExecute(t$con, glue::glue("SELECT * FROM {i} LIMIT 1")) > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_equal(., 0)
    }
  }

  unlink("project-1.motus")  
})

