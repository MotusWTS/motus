test_that("sunRiseSet() aligns with dates", {
  
  t <- dplyr::tibble(
    date = as.POSIXct(c("2023-01-01 04:00:00", "2023-01-01 20:00:00"),
                      tz = "America/Winnipeg"),
    date_utc = lubridate::with_tz(date, "UTC"),
    lat = 49.895, lon = -97.138) %>%
    dplyr::mutate(ts = as.numeric(date)) # numeric is always UTC
  
  expect_silent(s <- sunRiseSet(t, lat = "lat", lon = "lon"))
  expect_named(s, c(names(t), "sunrise", "sunset"))
  
  # Return same times because local dates the same even if UTC dates are different
  expect_true(lubridate::as_date(s$date[1]) == lubridate::as_date(s$date[2]))
  expect_false(lubridate::as_date(s$date_utc[1]) == lubridate::as_date(s$date_utc[2]))
  expect_equal(s$sunrise[1], s$sunrise[2])
  expect_equal(s$sunset[1], s$sunset[2])
  
  expect_equal(lubridate::floor_date(s$sunrise[1]), 
               as.POSIXct("2023-01-01 14:27:50", tz = "UTC"))
  expect_equal(lubridate::floor_date(s$sunset[1]), 
               as.POSIXct("2023-01-01 22:38:30", tz = "UTC"))
})

test_that("sunRiseSet() returns sunset times", {
  
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), 
            to = ".")
  t <- tagme(176, update = FALSE, new = FALSE)
  
  expect_message(s1 <- sunRiseSet(t), "'df_src' is a complete motus data base") %>%
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
