test_that("timeToSunriset() aligns with dates", {
  
  t <- dplyr::tibble(
    date = as.POSIXct(c("2023-01-01 04:00:00", "2023-01-01 20:00:00"),
                      tz = "America/Winnipeg"),
    date_utc = lubridate::with_tz(date, "UTC"),
    lat = 49.895, lon = -97.138) %>%
    dplyr::mutate(ts = as.numeric(date)) # numeric is always UTC
  
  expect_silent(s <- timeToSunriset(t, lat = "lat", lon = "lon"))
  expect_true(all(c("sunrise", "sunset", 
                    "ts_to_rise", "ts_to_set", 
                    "ts_since_set", "ts_since_rise") %in% names(s)))
              
  # Return same times because local dates the same even if UTC dates are different
  expect_equal(round(s$ts_to_rise, 2),    c(4.46, 12.46))
  expect_equal(round(s$ts_to_set, 2),     c(12.64, 20.66))
  expect_equal(round(s$ts_since_rise, 2), c(19.54, 11.54))
  expect_equal(round(s$ts_since_set, 2),  c(11.37, 3.36))
  
  # Note that sunrise/sets should be the same, because in 'local' time these
  # dates are the same day! In UTC they are different dates here we want the 
  # sunrise/sunset of the actual local day.
  expect_equal(lubridate::floor_date(s$sunrise), 
               as.POSIXct(c("2023-01-01 14:27:50", 
                            "2023-01-01 14:27:50"), tz = "UTC"))
  expect_equal(lubridate::floor_date(s$sunset), 
               as.POSIXct(c("2023-01-01 22:38:30", 
                            "2023-01-01 22:38:30"), tz = "UTC"))
})
