
# filterByActivity --------------------------------------------------------
test_that("filterByActivity filters as expected", {
  tags <- tagmeSample()
  
  expect_silent(a <- filterByActivity(tags, return = "all")) %>%
    expect_s3_class("tbl")
  expect_silent(g <- filterByActivity(tags)) %>%
    expect_s3_class("tbl")
  expect_silent(b <- filterByActivity(tags, return = "bad")) %>%
    expect_s3_class("tbl")
  
  # 'good' and 'bad' should be subsets of 'all'
  expect_equal(nrow(a <- dplyr::collect(a)), 
               nrow(g <- dplyr::collect(g)) + nrow(b <- dplyr::collect(b)))
                 
  expect_equal(dplyr::arrange(a, .data$probability, .data$hitID) %>%
                 dplyr::select("probability", "hitID"),
               dplyr::arrange(rbind(b, g), .data$probability, .data$hitID) %>%
                 dplyr::select("probability", "hitID"))
  
  # Matches motusFilter results
  runs <- dplyr::tbl(tags, "runs") %>%
    dplyr::select(runID, batchID = batchIDbegin, 
                  runLen = len, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect() %>%
    dplyr::filter(runID != 2358172, batchID != 1991040)  #Extra filtering applied
  
  a <- a %>%
    dplyr::mutate(motusFilter = as.numeric(probability)) %>%
    dplyr::select(runID, batchID, runLen, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect() %>%
    dplyr::filter(runID != 2358172, batchID != 1991040) #Extra filtering applied
  
  expect_equal(runs, dplyr::arrange(a, runID))
})

test_that("Good/Bad runs change depending on parameters", {
  tags <- tagmeSample()
  
  # Expect run lengths to change if adjust the parameters
  expect_silent(a <- filterByActivity(tags, minLen = 10, 
                                      maxLen = 15, return = "all"))
  expect_equal(dplyr::filter(a, runLen <= 10) %>%
                 dplyr::summarize(probability = 
                                    sum(probability, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  expect_equal(dplyr::filter(a, runLen >= 15) %>%
                 dplyr::summarize(probability = 
                                    sum(probability == 0, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  

  expect_silent(a <- filterByActivity(tags, minLen = 2,
                                      maxLen = 5, return = "all"))
  expect_equal(dplyr::filter(a, runLen <= 2) %>%
                 dplyr::summarize(probability = 
                                    sum(probability, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  expect_equal(dplyr::filter(a, runLen >= 5) %>%
                 dplyr::summarize(probability = 
                                    sum(probability == 0, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
})

test_that("Empty activity table stops", {
  tags <- withr::local_db_connection(tagmeSample())
  
  # Empty activity
  DBI_Execute(tags, "DELETE FROM activity")
  expect_error(a <- filterByActivity(tags, return = "all"),
               "'activity' table is empty, cannot filter by activity")
  
  # No activity
  DBI::dbRemoveTable(tags, "activity")
  expect_error(a <- filterByActivity(tags, return = "all"),
               "'src' must contain at least tables 'activity', 'alltags',")
})




# deprecateBatches() -------------------------------------


test_that("SAMPLE - remove deprecated batches", {
  sample_auth()
  
  t <- withr::local_db_connection(tagmeSample())
  
  # Deprecated batches listed, but not removed to start
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 0))
  
  # Make fake deprecated batches
  d <- dep$batchID
  
  # To start, expect deprecated batches in data
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_gt(., 0)
  
  for(i in DBI::dbListTables(t)) {
    if("batchID" %in% DBI::dbListFields(t, i) &
       nrow(DBI_Query(t, "SELECT * FROM {`i`} LIMIT 1")) > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_gt(., 0)
    }
  }
  
  # Deprecate batches
  expect_message(removeDeprecated(t, ask = FALSE)) %>%
    suppressMessages
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 1))
  
  # With deprecated, expect deprecated batches removed
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% !!d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_equal(., 0)
  
  for(i in DBI::dbListTables(t)) {
    if("batchID" %in% DBI::dbListFields(t, i) &
       DBI_Execute(t, "SELECT * FROM {i} LIMIT 1") > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_equal(., 0)
    }
  }
})


test_that("PROJ 1 - remove deprecated batches", {
  skip_if_no_server()
  skip_if_no_auth()
  withr::local_file("project-1.motus")
  withr::local_db_connection(
    suppressMessages(t <- tagme(1, new = TRUE)))
  
  # Deprecated batches listed, but not removed to start
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 0))
  
  # Make fake deprecated batches from real batches (in runs) not yet deprecated
  d <- dplyr::tbl(t, "runs") %>%
    dplyr::filter(!batchIDbegin %in% !!dep$batchID) %>%
    dplyr::pull(batchIDbegin) %>%
    unique()
  data.frame(batchID = d, batchFilter = 4, removed = 0) %>%
    DBI::dbWriteTable(t, "deprecated", ., append = TRUE)
  
  # To start, expect deprecated batches in data
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_gt(., 0)
  
  for(i in DBI::dbListTables(t)) {
    if("batchID" %in% DBI::dbListFields(t, i) &
       DBI_Execute(t, "SELECT * FROM {i} LIMIT 1") > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_gt(., 0)
    }
  }

  # Deprecate batches
  expect_message(removeDeprecated(t, ask = FALSE)) %>%
    suppressMessages()
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 1))

  # With deprecated, expect deprecated batches removed
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% !!d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_equal(., 0)
  
  for(i in DBI::dbListTables(t)) {
    if("batchID" %in% DBI::dbListFields(t, i) &
       DBI_Execute(t, "SELECT * FROM {i} LIMIT 1") > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_equal(., 0)
    }
  }
})


test_that("RECV - remove deprecated batches", {
  skip_if_no_server()
  skip_if_no_auth()

  # Jump start database at batch number to have runs
  s <- srvAuth() # Authorize to update data versions
  withr::local_file(list("SG-4002BBBK1580.motus"))
  withr::local_db_connection(t <- tagme("SG-4002BBBK1580", update = FALSE, new = TRUE))
  deviceID <- srvDeviceIDForReceiver(get_projRecv(t))[[2]]
  ensureDBTables(t, get_projRecv(t), deviceID)
  DBI::dbExecute(t, "INSERT INTO batches (batchID) VALUES (2733020)")
  
  # Get some runs
  suppressMessages(t <- tagme("SG-4002BBBK1580", update = TRUE, new = FALSE))

  # Deprecated batches listed, but not removed to start
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 0))
  
  # Make fake deprecated batches
  d <- dplyr::tbl(t, "runs") %>%
    dplyr::filter(!batchIDbegin %in% !!dep$batchID) %>%
    dplyr::pull(batchIDbegin) %>%
    unique()
  data.frame(batchID = d, batchFilter = 4, removed = 0) %>%
    DBI::dbWriteTable(t, "deprecated", ., append = TRUE)
  
  # To start, expect deprecated batches in data
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_gt(., 0)
  
  for(i in DBI::dbListTables(t)) {
    if("batchID" %in% DBI::dbListFields(t, i) &
       DBI::dbExecute(t, glue::glue("SELECT * FROM {i} LIMIT 1")) > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_gt(., 0)
    }
  }
  
  # Deprecate batches
  expect_message(removeDeprecated(t, ask = FALSE)) %>%
    suppressMessages()
  dep <- dplyr::tbl(t, "deprecated") %>% 
    dplyr::collect()
  expect_gt(nrow(dep), 0)
  expect_true(all(dep$removed == 1))
  
  # With deprecated, expect deprecated batches removed
  dplyr::tbl(t, "runs") %>% 
    dplyr::filter(.data$batchIDbegin %in% !!d) %>%
    dplyr::collect() %>%
    nrow() %>%
    expect_equal(., 0)
  
  for(i in DBI::dbListTables(t)) {
    if("batchID" %in% DBI::dbListFields(t, i) &
       DBI::dbExecute(t, glue::glue("SELECT * FROM {i} LIMIT 1")) > 0) {
      dplyr::tbl(t, i) %>% 
        dplyr::filter(.data$batchID %in% !!d) %>%
        dplyr::collect() %>%
        nrow() %>%
        expect_equal(., 0)
    }
  }
})
