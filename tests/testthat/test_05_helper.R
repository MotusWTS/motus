teardown(unlink("project-176.motus"))


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
  expect_equal(dplyr::filter(a, probability == 1) %>% dplyr::collect(), 
               dplyr::collect(g))
  expect_equal(dplyr::filter(a, probability == 0) %>% dplyr::collect(), 
               dplyr::collect(b))
  
  # Matches motusFilter results
  runs <- dplyr::tbl(shorebirds_sql, "runs") %>%
    dplyr::select(runID, batchID = batchIDbegin, runLen = len, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect()
  
  a <- a %>%
    dplyr::mutate(motusFilter = as.integer(probability)) %>%
    dplyr::select(runID, batchID, runLen, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect()
  
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
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
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


test_that("prepData() handles both data.frame and src", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  tags <- DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus")
  alltags <- dplyr::tbl(tags, "alltags") %>%
    dplyr::filter(batchID == 667134)
  
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

test_that("calcGPS() matches GPS", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  # GPS data (1 day)
  tags <- DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus")
  
  # Daily Join
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags))) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_equal(unique(g$timeBin), 18170)
  g <- dplyr::select(g, -hitID, -ts) %>% dplyr::distinct() %>% as.data.frame()
  expect_equal(nrow(g), length(unique(g$batchID)))
  
  expect_silent(getGPS(tags, by = "daily")) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt"))
  
  # By = 60
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags), by = 60)) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_length(unique(g$timeBin), 24)
  expect_equal(g$gpsID_min, g$gpsID_max) # No medians
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID = gpsID_min, 
                                       gpsLat, gpsLon, gpsAlt), 
                          dplyr::collect(dplyr::tbl(tags, "gps")))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_true(all(abs(g1$hitts - g1$ts) <= 60 * 60))
  
  expect_silent(getGPS(tags, by = 60)) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt"))
  
  # By = 5 seconds
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags), by = 5/60)) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_length(unique(g$timeBin), 4)
  expect_equal(g$gpsID_min, g$gpsID_max) # No medians
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID = gpsID_min, 
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_true(all(abs(g1$hitts - g1$ts) <= 5))
  
  expect_silent(getGPS(tags, by = 5/60)) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt"))
  
  
  # By = "closest"
  expect_message(g <- calcGPS(prepGPS(tags), prepData(tags), by = "closest"),
                 "Max time difference") %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true("gpsID" %in% names(g)) # exact match with gpsID, not range
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID,
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_true(all(abs(g1$hitts - g1$ts) <= 33*60))

  expect_message(getGPS(tags, by = "closest"), "Max time difference") %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt"))
  
  DBI::dbDisconnect(tags)
  unlink("gps_sample.motus")
})   

test_that("getGPS errors", {
  expect_error(getGPS(tags, by = "daaaaily"))
  expect_error(getGPS(tags, by = 0))
  expect_error(getGPS(tags, by = -100))
})

test_that("calcGPS() matches GPS with subset", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  # GPS data (1 day)
  tags <- DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus")
  alltags <- dplyr::tbl(tags, "alltags") %>%
    dplyr::filter(batchID == 667134) %>%
    dplyr::collect()
  
  # Daily Join
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags, alltags))) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_equal(unique(g$timeBin), 18170)
  g <- dplyr::select(g, -hitID, -ts) %>% dplyr::distinct() %>% as.data.frame()
  expect_equal(nrow(g), length(unique(g$batchID)))
  
  expect_silent(getGPS(tags, by = "daily")) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt"))
  
  # By = 60
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags, alltags), by = 60)) %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_length(unique(g$timeBin), 1)
  expect_equal(g$gpsID_min, g$gpsID_max) # No medians
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID = gpsID_min, 
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_true(all(abs(g1$hitts - g1$ts) <= 60 * 60))
  
  expect_silent(getGPS(tags, by = 60)) %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt"))
  
  # By = 5 seconds
  expect_silent(g <- calcGPS(prepGPS(tags), prepData(tags, alltags), by = 5/60)) %>%
    expect_is("data.frame")
  expect_equal(nrow(g), 0) # No GPS points
  
  
  # By = "closest"
  expect_message(g <- calcGPS(prepGPS(tags), prepData(tags, alltags), by = "closest"),
                 "Max time difference") %>%
    expect_is("data.frame")
  expect_gt(nrow(g), 0) # GPS points
  expect_equal(nrow(g[is.na(g$gpsLat),]), 0) # No missing GPS points
  expect_equal(max(table(g$hitID)), 1) # No duplicate hitIDs
  expect_true("gpsID" %in% names(g)) # exact match with gpsID, not range
  g1 <- dplyr::left_join(dplyr::select(g, hitts = ts, gpsID,
                                       gpsLat, gpsLon, gpsAlt), 
                         dplyr::collect(dplyr::tbl(tags, "gps")))
  expect_equal(g1$gpsLat, g1$lat)
  expect_equal(g1$gpsLon, g1$lon)
  expect_equal(g1$gpsAlt, g1$alt)
  expect_true(all(abs(g1$hitts - g1$ts) <= 33*60))
  
  expect_message(getGPS(tags, by = "closest"), "Max time difference") %>%
    expect_named(c("hitID", "gpsLat", "gpsLon", "gpsAlt"))
  
  DBI::dbDisconnect(tags)
  unlink("gps_sample.motus")
})   


test_that("calcGPS() keepAll = TRUE", {
  file.copy(system.file("extdata", "gps_sample.motus", package = "motus"), ".")
  
  # GPS data (1 day)
  tags <- DBI::dbConnect(RSQLite::SQLite(), "gps_sample.motus")
  
  # Daily Join
  expect_silent(g1 <- calcGPS(prepGPS(tags), prepData(tags))) %>%
    expect_is("data.frame")
  expect_silent(g2 <- calcGPS(prepGPS(tags), prepData(tags), keepAll = TRUE)) %>%
    expect_is("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
  
  # By = 60
  expect_silent(g1 <- calcGPS(prepGPS(tags), prepData(tags), by = 60)) %>%
    expect_is("data.frame")
  expect_silent(g2 <- calcGPS(prepGPS(tags), prepData(tags), by = 60, 
                              keepAll = TRUE)) %>%
    expect_is("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
  
  # By = 5 seconds
  expect_silent(g1 <- calcGPS(prepGPS(tags), prepData(tags), by = 5/60)) %>%
    expect_is("data.frame")
  expect_silent(g2 <- calcGPS(prepGPS(tags), prepData(tags), by = 5/60,
                              keepAll = TRUE)) %>%
    expect_is("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
  
  # By = "closest"
  expect_message(g1 <- calcGPS(prepGPS(tags), prepData(tags), by = "closest"),
                 "Max time difference") %>%
    expect_is("data.frame")
  expect_message(g2 <- calcGPS(prepGPS(tags), prepData(tags), by = "closest", 
                               keepAll = TRUE),
                 "Max time difference") %>%
    expect_is("data.frame")
  
  expect_gt(nrow(g2), nrow(g1))
  expect_true(all(is.na(dplyr::anti_join(g2, g1, by = "hitID")$gpsLat)))
  expect_false(any(is.na(g2$hitID)))
  expect_equal(dplyr::collect(prepData(tags))$hitID,
               g2$hitID)
  
  DBI::dbDisconnect(tags)
  unlink("gps_sample.motus")
})   

