test_that("tagme() blu project", {
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # Setup mid-point project
  withr::local_options(motus.test.max = 1)
  withr::local_file(list("project-622.motus"))
  withr::local_db_connection({
    t <- tagme(
      622, update = TRUE, new = TRUE, 
      skipActivity = TRUE, skipDeprecated = TRUE, 
      skipNodes = TRUE)
  }) %>%
    suppressMessages()
  
  # CHECKS

  # Add dummy batches so we skip ahead to blu tag range 
  # >=26750685, 26751098, 26752853 (don't use the first)
  DBI::dbExecute(t, "INSERT INTO batches (batchID) VALUES (26751098), (26752850)")
  DBI::dbExecute(t, "INSERT INTO projBatch (tagDepProjectID, batchID, maxHitID) VALUES (622, 26751098, 0), (622, 26752850, 0)")

  # Ensure blu fetched
  withr::local_options(motus.test.max = 5)
  withr::local_db_connection({
    t <- tagme(622, update = TRUE, new = FALSE, 
      skipActivity = TRUE, 
      skipDeprecated = TRUE, 
      skipNodes = TRUE)
    }) %>%
    expect_message("Checking for new data") %>%
    expect_message("hitsBlu") %>%
    suppressMessages()

  tt <- DBI::dbReadTable(t, "hitsBlu")
  expect_gt(nrow(tt), 0)
  expect_gt(min(tt$batchID), 26750685) # Expect missing first batch
  
  # Fill in missing blu tags
  hitsBlu(t) %>%
    expect_message("Checking blu tag batch history") %>%
    expect_message("hitsBlu starting at") %>%
    suppressMessages()
  tt2 <- DBI::dbReadTable(t, "hitsBlu")
  expect_gt(nrow(tt2), nrow(tt)) # Expect have the first batch
  expect_equal(min(tt2$batchID), 26750685)

})

test_that("tagme() blu receivers", {
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # Setup mid-point project
  # (quicker to create manually than touch API)
  s <- srvAuth() # Authorize to update data versions
  withr::local_file(list("CTT-6CA25D375881.motus"))
  withr::local_db_connection(t <- tagme("CTT-6CA25D375881", update = FALSE, new = TRUE))
  deviceID <- srvDeviceIDForReceiver(get_projRecv(t))[[2]]
  ensureDBTables(t, get_projRecv(t), deviceID)
  
  # Add dummy batches to skip ahead to blu tag range
  # < 26750744 (add batches before, then test by removing blutags)
  # (but cannot start on batch that doesn't exist, check "batches" table/call)
  DBI::dbExecute(t, "INSERT INTO batches (batchID) VALUES (26750740)")

  # Ensure blu fetched
  withr::local_options(motus.test.max = 5)
  withr::local_db_connection({
    t <- tagme(
      "CTT-6CA25D375881",
      update = TRUE,
      new = FALSE,
      skipActivity = TRUE,
      skipDeprecated = TRUE,
      skipNodes = TRUE
    )
    }) %>%
    expect_message("Checking for new data") %>%
    expect_message("hitsBlu") %>%
    suppressMessages()

  # Have blu tag hits
  tt <- DBI::dbReadTable(t, "hitsBlu")
  expect_gt(nrow(tt), 0)

  # Remove starting hits
  DBI::dbExecute(t, "DELETE FROM hitsBlu WHERE batchID IN (26750744)")
  tt <- DBI::dbReadTable(t, "hitsBlu")
  expect_gt(min(tt$batchID), 26750744)
  
  # Fill in missing blu tags
  hitsBlu(t) %>%
    expect_message("Checking blu tag batch history") %>%
    expect_message("hitsBlu starting at")
  tt2 <- DBI::dbReadTable(t, "hitsBlu")
  expect_gt(nrow(tt2), nrow(tt)) # Now have the earlier hits
  expect_equal(min(tt2$batchID), 26750744)
  })