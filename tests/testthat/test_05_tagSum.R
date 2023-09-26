test_that("tagSum()", {
  testthat::local_edition(3)
  
  t <- tagmeSample()
  df <- dplyr::tbl(t, "alltagsGPS") %>%
    dplyr::collect()
  
  expect_silent(tags <- tagSum(df))
  expect_s3_class(tags, "data.frame")

  # Not Interactive
  expect_snapshot_value(tags, style = "json2")

})
