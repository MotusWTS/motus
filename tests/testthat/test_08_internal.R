context("low level functions") 

setup({
  unlink("project-176.motus")
  unlink("SG-3115BBBK0782.motus")
})

teardown({
  unlink("project-176.motus")
  unlink("SG-3115BBBK0782.motus")
})

test_that("hitsByBatchProject doesn't fail on extra columns", {
  sample_auth()
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  tags <- safeSQL(tagme(176, new = FALSE, update = FALSE))
  DBI::dbExecute(tags$con, "DELETE FROM projBatch")
  DBI::dbExecute(tags$con, "DELETE FROM hits")
  
  
  expect_silent(h0 <- srvHitsForTagProject(projectID = 176, 
                                           batchID = 53, 
                                           hitID = 0))
  expect_message(h1 <- hitsForBatchProject(sql = tags, 
                                           projectID = 176, 
                                           batchID = 53,
                                           batchMsg = "temp"))
  expect_gt(h1, 0)
  expect_true(dplyr::all_equal(h0, dplyr::tbl(tags$con, "hits") %>% 
                                 dplyr::collect() %>% 
                                 as.data.frame(), 
                               convert = TRUE))
  
  # Expect extra columns to NOT result in an error
  DBI::dbExecute(tags$con, "DELETE FROM projBatch")
  DBI::dbExecute(tags$con, "DELETE FROM hits")
  m <- mockery::mock(dplyr::mutate(h0, EXTRA_COL = 0), data.frame())
  with_mock("motus:::srvHitsForTagProject" = m,
            expect_message(hitsForBatchProject(sql = tags, 
                                               projectID = 176, 
                                               batchID = 53,
                                               batchMsg = "temp")))
})

test_that("hitsByBatchReceiver doesn't fail on extra columns", {
  skip_if_no_auth()
  f <- system.file("extdata", "SG-3115BBBK0782.motus", package = "motus")
  skip_if_no_file(f)
  
  file.copy(f, ".")
  tags <- safeSQL(tagme("SG-3115BBBK0782", new = FALSE, update = FALSE))
  DBI::dbExecute(tags$con, "DELETE FROM hits")
  
  expect_silent(h0 <- srvHitsForReceiver(batchID = 417054, 
                                         hitID = 0))
  expect_message(hitsForBatchReceiver(sql = tags, 
                                      batchID = 417054,
                                      batchMsg = "temp"))
  expect_true(dplyr::all_equal(h0, dplyr::tbl(tags$con, "hits") %>% 
                                 dplyr::collect() %>% 
                                 as.data.frame(), 
                               convert = TRUE))
  
  # Expect extra columns to NOT result in an error
  DBI::dbExecute(tags$con, "DELETE FROM hits")
  m <- mockery::mock(dplyr::mutate(h0, EXTRA_COL = 0), data.frame())
  with_mock("motus:::srvHitsForReceiver" = m,
            expect_message(hitsForBatchReceiver(sql = tags, 
                                                batchID = 53,
                                                batchMsg = "temp")))
})