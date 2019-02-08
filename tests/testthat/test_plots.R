context("Plotting functions")


test_that("Plots run with no errors", {
  shorebirds_sql <- motus::tagme(176, update = FALSE, dir = system.file("extdata", package = "motus"))
  expect_silent(plotAllTagsCoord(shorebirds))
  expect_silent(plotAllTagsSite(shorebirds))
  expect_silent(plotDailySiteSum(shorebirds, "Longridge"))
  expect_silent(plotRouteMap(shorebirds_sql, recvStart = "2016-01-01", recvEnd = "2016-12-31"))
  expect_silent(plotSite(shorebirds))
  expect_silent(plotSiteSig(shorebirds, "Longridge"))
  expect_silent(plotTagSig(shorebirds, "16035"))
})