context("Compare server to R")

test_that("table fields match server", {
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  tags <- DBI::dbConnect(
    RSQLite::SQLite(), 
    system.file("extdata", "project-176.motus", package = "motus"))

  expect_named(
    srvActivityForBatches(batchID = 53)[1,],
    DBI::dbListFields(tags, "activity"), ignore.order = TRUE)
  
  expect_named(
    srvBatchesForTagProject(projectID = 176, batchID = 53)[1,],
    DBI::dbListFields(tags, "batches"), ignore.order = TRUE)
  
  expect_named(
    srvHitsForTagProject(projectID = 176, batchID = 53, hitID = 45107)[1,],
    DBI::dbListFields(tags, "hits"), ignore.order = TRUE)
  
  expect_named(
    srvProjectAmbiguitiesForTagProject(projectID = 176),
    DBI::dbListFields(tags, "projAmbig"), ignore.order = TRUE)
  
  expect_named(
    srvRunsForTagProject(projectID = 176, batchID = 53, runID = 8886)[1,],
    DBI::dbListFields(tags, "runs"), ignore.order = TRUE)
  
  expect_named(
    srvGPSforTagProject(projectID = 176, batchID = 53, ts = 0)[1,],
    DBI::dbListFields(tags, "gps"), ignore.order = TRUE)
})
  