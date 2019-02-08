context("Plotting functions")


test_that("Plots run with no errors", {
  expect_silent(plotAllTagsCoord(shorebirds))
  expect_silent(plotAllTagsSite(shorebirds))
  expect_silent(plotDailySiteSum(shorebirds, "Longridge"))
  expect_silent(plotRouteMap(shorebirds))
  expect_silent(plotSite(shorebirds))
  expect_silent(plotSiteSig(shorebirds, "Longridge"))
  expect_silent(plotTagSig(shorebirds, "16035"))
})