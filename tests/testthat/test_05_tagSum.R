test_that("tagSum()", {
  t <- withr::local_db_connection(tagmeSample())
  
  df <- dplyr::tbl(t, "alltagsGPS") %>%
    dplyr::collect()
  
  expect_silent(tags <- tagSum(df))
  expect_s3_class(tags, "data.frame")

  # Not Interactive
  expect_snapshot_value(tags, style = "json2")
})
