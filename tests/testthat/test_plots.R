context("Plotting functions")


test_that("Plots run with no errors", {
  shorebirds_sql <- motus::tagme(176, update = FALSE, dir = system.file("extdata", package = "motus"))
  shorebirds_sub <- dplyr::filter(shorebirds, motusTagID %in% c(19129, 16011, 17357, 16035, 22897, 23316)) 
  
  expect_silent(plotAllTagsCoord(shorebirds))
  expect_silent(plotAllTagsCoord(shorebirds_sub))
  expect_silent(plotAllTagsCoord(dplyr::tbl(shorebirds_sql, "alltags")))
  
  expect_silent(plotAllTagsSite(shorebirds))
  expect_silent(plotAllTagsSite(dplyr::tbl(shorebirds_sql, "alltags")))
  
  expect_silent(plotDailySiteSum(shorebirds, "Longridge"))
  expect_silent(plotDailySiteSum(dplyr::tbl(shorebirds_sql, "alltags"), "Longridge"))
  
  expect_error(expect_warning(plotRouteMap(shorebirds_sql, recvStart = "2016-01-01", recvEnd = "2016-12-31"), NA), NA)
  
  expect_silent(plotSite(shorebirds))
  expect_silent(plotSite(dplyr::tbl(shorebirds_sql, "alltags")))
  
  expect_silent(plotSiteSig(shorebirds, "Longridge"))
  expect_silent(plotSiteSig(dplyr::tbl(shorebirds_sql, "alltags"), "Longridge"))
  
  expect_silent(plotTagSig(shorebirds, "16035"))
  expect_silent(plotTagSig(dplyr::tbl(shorebirds_sql, "alltags"), "16035"))
  
  expect_message(plotRouteMap(shorebirds_sql))
  expect_silent(plotRouteMap(shorebirds_sql, recvStart = "2016-01-01", recvEnd = "2016-12-31"))
  
  # Clean up
  file.remove("Rplots.pdf")
})