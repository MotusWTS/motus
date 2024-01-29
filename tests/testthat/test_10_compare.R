test_that("table fields match server (sample auth)", {
  skip_if_no_server()
  sample_auth()
  tags <- withr::local_db_connection(tagmeSample())
  
  # TODO: Update once API updated
  expect_named(srvActivityForAll(batchID = 53)[1,] %>% dplyr::select(-"year", -"month", -"day"),
               DBI::dbListFields(tags, "activityAll"), ignore.order = TRUE)
  
  # TODO: Update once API updated
  expect_named(srvActivityForBatches(batchID = 53)[1,] %>% dplyr::select(-"year", -"month", -"day"),
               DBI::dbListFields(tags, "activity"), ignore.order = TRUE)
  
  expect_named(srvBatchesForTagProject(projectID = 176, batchID = 53)[1,],
          c(DBI::dbListFields(tags, "batches"), "version"), ignore.order = TRUE)
  
  expect_named(srvHitsForTagProject(projectID = 176, batchID = 53, hitID = 45107)[1,],
               DBI::dbListFields(tags, "hits"), ignore.order = TRUE)
  
  expect_named(srvProjectAmbiguitiesForTagProject(projectID = 176),
               DBI::dbListFields(tags, "projAmbig"), ignore.order = TRUE)
  
  expect_named(srvRunsForTagProject(projectID = 176, batchID = 53, runID = 8886)[1,],
               DBI::dbListFields(tags, "runs"), ignore.order = TRUE)
  
  expect_named(srvGPSForTagProject(projectID = 176, batchID = 53, gpsID = 0)[1,],
               DBI::dbListFields(tags, "gps"), ignore.order = TRUE)
  
  # TODO: Update once sample data has nodeData
  #expect_named(
  #  srvNodes(projectID = 176, batchID = 53, nodeDataID = 0)[1,],
  #  c(DBI::dbListFields(tags, "nodeData"), "projectID"), ignore.order = TRUE)
})

test_that("table fields match server (local auth)", {
  skip_if_no_server()
  skip_if_no_auth()
  skip_if_no_file(f <- "project-4.motus")
  tags <- withr::local_db_connection(tagmeSample(f))
  
  # TODO: Update once API updated
  expect_named(
    srvActivityForBatches(batchID = 53)[1,] %>% dplyr::select(-"year", -"month", -"day"),
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

  