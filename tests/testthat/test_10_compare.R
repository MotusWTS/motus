context("Compare server to R")

test_that("table fields match server (sample auth)", {
  sample_auth()
  
  tags <- DBI::dbConnect(
    RSQLite::SQLite(), 
    system.file("extdata", "project-176.motus", package = "motus"))
  
  expect_true(
    all(names(srvActivityForBatches(batchID = 53)[1,]) %in%
          DBI::dbListFields(tags, "activity")))
  
  expect_true(
    all(names(srvBatchesForTagProject(projectID = 176, batchID = 53)[1,]) %in%
          c(DBI::dbListFields(tags, "batches"), "version")))
  
  expect_true(
    all(names(srvHitsForTagProject(projectID = 176, batchID = 53, hitID = 45107)[1,]) %in%
              DBI::dbListFields(tags, "hits"), ignore.order = TRUE))
  
  expect_true(
    all(names(srvProjectAmbiguitiesForTagProject(projectID = 176)) %in%
          DBI::dbListFields(tags, "projAmbig")))
  
  expect_true(
    all(names(srvRunsForTagProject(projectID = 176, batchID = 53, runID = 8886)[1,]) %in%
          DBI::dbListFields(tags, "runs")))
  
  expect_true(
    all(names(srvGPSForTagProject(projectID = 176, batchID = 53, gpsID = 0)[1,]) %in%
        DBI::dbListFields(tags, "gps")))
  
  # Update once sample data has nodeData
  #expect_named(
  #  srvNodes(projectID = 176, batchID = 53, nodeDataID = 0)[1,],
  #  c(DBI::dbListFields(tags, "nodeData"), "projectID"), ignore.order = TRUE)
})

test_that("table fields match server (local auth)", {

  skip_if_no_auth()
  skip_if_no_file(f <- system.file("extdata", "project-4.motus", package = "motus"))
  
  tags <- DBI::dbConnect(RSQLite::SQLite(), f)
  
  expect_named(
    srvActivityForBatches(batchID = 53)[1,],
    DBI::dbListFields(tags, "activity"), ignore.order = TRUE)
  
  expect_named(
    srvBatchesForTagProject(projectID = 4, batchID = 53)[1,],
    c(DBI::dbListFields(tags, "batches"), "version"), ignore.order = TRUE)
  
  expect_named(
    srvHitsForTagProject(projectID = 4, batchID = 53, hitID = 45107)[1,],
    DBI::dbListFields(tags, "hits"), ignore.order = TRUE)
  
  expect_named(
    srvProjectAmbiguitiesForTagProject(projectID = 4),
    DBI::dbListFields(tags, "projAmbig"), ignore.order = TRUE)
  
  expect_named(
    srvRunsForTagProject(projectID = 4, batchID = 53, runID = 8886)[1,],
    DBI::dbListFields(tags, "runs"), ignore.order = TRUE)
  
  expect_named(
    srvGPSForTagProject(projectID = 4, batchID = 53, gpsID = 0)[1,],
    DBI::dbListFields(tags, "gps"), ignore.order = TRUE)
  
  expect_named(
    srvNodes(projectID = 4, batchID = 53, nodeDataID = 0)[1,],
    c(DBI::dbListFields(tags, "nodeData"), "projectID"), ignore.order = TRUE)
})

  