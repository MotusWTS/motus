test_that("sunriset()", {
  expect_silent(s <- sunriset(
    -97.138, 49.895, 
    as.POSIXct("2023-01-01 10:00:00", "America/Winnipeg"), 
    "sunrise"))
  expect_s3_class(s, "POSIXct")
  expect_equal(round(s), 
               as.POSIXct("2023-01-01 08:26:35", tz = "America/Winnipeg"))
})

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
  expect_equal(dplyr::tbl(t, "alltags") %>% 
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
  
  disconnect(t)
  unlink("project-176.motus")
})
