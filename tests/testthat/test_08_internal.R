test_that("hitsByBatchProject doesn't fail on extra columns", {
  sample_auth()
  tags <- tagmeSample()
  DBI_Execute(tags, "DELETE FROM projBatch")
  DBI_Execute(tags, "DELETE FROM hits")
  
  expect_silent(h0 <- srvHitsForTagProject(projectID = 176, 
                                           batchID = 53, 
                                           hitID = 0))
  expect_message(h1 <- hitsForBatchProject(tags, 
                                           projectID = 176, 
                                           batchID = 53,
                                           batchMsg = "temp"))
  expect_gt(h1, 0)
  expect_equal(
    h0, 
    dplyr::tbl(tags, "hits") %>% 
      dplyr::collect() %>% 
      as.data.frame() %>% 
      dplyr::mutate(validated = as.logical(validated)))
  
  # Expect extra columns to NOT result in an error
  DBI_Execute(tags, "DELETE FROM projBatch")
  DBI_Execute(tags, "DELETE FROM hits")
  
  
  mock <- mockery::mock(dplyr::mutate(h0, EXTRA_COL = 0),
                        data.frame(), cycle = TRUE)
  mockery::stub(hitsForBatchProject, "srvHitsForTagProject", mock)
  
  expect_message(hitsForBatchProject(tags, 
                                     projectID = 176, 
                                     batchID = 53,
                                     batchMsg = "temp"))
  mockery::expect_called(mock, 2)
})

test_that("hitsByBatchReceiver doesn't fail on extra columns", {
  skip_if_no_auth()
  withr::local_file("SG-3115BBBK0782.motus")
  tags <- withr::local_db_connection(tagmeSample("SG-3115BBBK0782.motus"))
  
  b <- DBI_Query(tags, "SELECT batchID FROM hits LIMIT 1")
  DBI_Execute(tags, "DELETE FROM hits")
  
  expect_silent(h0 <- srvHitsForReceiver(batchID = b, hitID = 0))
  expect_true(nrow(h0) > 0)
  expect_message(hitsForBatchReceiver(tags, batchID = b, batchMsg = "temp"))
  expect_equal(h0$hitID, 
               dplyr::tbl(tags, "hits") %>% 
                 dplyr::collect() %>% 
                 dplyr::pull(hitID) %>% 
                 as.numeric())
  
  # Expect extra columns to NOT result in an error
  DBI_Execute(tags, "DELETE FROM hits")
  
  # first extra col, then no rows to stop
  mock <- mockery::mock(dplyr::mutate(h0, EXTRA_COL = 0), 
                     data.frame(), cycle = TRUE)

  b <- dplyr::tbl(tags, "batches") %>% dplyr::pull(batchID)
  
  mockery::stub(hitsForBatchReceiver, "srvHitsForReceiver", mock)

  expect_message(hitsForBatchReceiver(tags, 
                                      batchID = b[1],
                                      batchMsg = "temp"))
  
  mockery::expect_called(mock, 2)
})
