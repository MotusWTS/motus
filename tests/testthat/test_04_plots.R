context("Plotting functions")

teardown(unlink("Rplots.pdf"))

test_that("Plots run with no errors", {
  tags_sql <- motus::tagme(176, update = FALSE, 
                           dir = system.file("extdata", package = "motus"))
  tags <- dplyr::tbl(tags_sql, "alltagsGPS") %>%
    dplyr::collect()
  
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
  expect_silent(plotSite(dplyr::tbl(tags_sql, "alltagsGPS")))
  
  expect_silent(plotSiteSig(tags, "Longridge"))
  expect_silent(plotSiteSig(dplyr::tbl(tags_sql, "alltagsGPS"), "Longridge"))
  
  expect_silent(plotTagSig(tags, "16035"))
  expect_silent(plotTagSig(dplyr::tbl(tags_sql, "alltagsGPS"), "16035"))
  
  skip_if_not_installed("ggmap")
  expect_message(plotRouteMap(tags_sql))
  expect_silent(plotRouteMap(tags_sql, recvStart = "2016-01-01", 
                             recvEnd = "2016-12-31"))
})
