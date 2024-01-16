test_that("Plots run with no errors", {
  withr::local_file("Rplots.pdf")
  tags_sql <- withr::local_db_connection(tagmeSample())
  tags <- tags_sql %>%
    dplyr::tbl("alltagsGPS") %>%
    suppressWarnings(dplyr::collect()) # Stupid dbDisconnect() warning
  
  tags_sub <- dplyr::filter(
    tags, motusTagID %in% c(19129, 16011, 17357, 16035, 22897, 23316))

  expect_silent(plotAllTagsCoord(tags))
  expect_silent(plotAllTagsCoord(tags_sub))
  expect_silent(plotAllTagsCoord(dplyr::tbl(tags_sql, "alltagsGPS")))

  expect_silent(plotAllTagsSite(tags))
  expect_silent(plotAllTagsSite(dplyr::tbl(tags_sql, "alltagsGPS")))

  expect_silent(plotDailySiteSum(tags, "Longridge"))
  expect_silent(plotDailySiteSum(dplyr::tbl(tags_sql, "alltagsGPS"), "Longridge"))

  expect_silent(plotSite(tags))
  expect_silent(plotSite(tags_sub, ncol = 2))
  expect_silent(plotSite(dplyr::tbl(tags_sql, "alltagsGPS")))
  expect_message(plotSite(tags_sql, sitename = "Piskwamish"), 
                 "'df_src' is a complete motus data base")

  expect_silent(plotSiteSig(tags, "Longridge"))
  expect_silent(plotSiteSig(dplyr::tbl(tags_sql, "alltagsGPS"), "Longridge"))

  expect_silent(plotTagSig(tags, "16035"))
  expect_silent(plotTagSig(dplyr::tbl(tags_sql, "alltagsGPS"), "16035"))

  skip_if_not_installed("ggspatial")
  skip_if_offline()
  withr::local_file("rosm.cache")
  expect_message(plotRouteMap(tags_sql), "Remember") |>
    suppressMessages()
  expect_message(plotRouteMap(tags_sql, start_date = "2016-01-01",
                              end_date = "2016-12-31")) |>
    suppressMessages()
})
