expect_silent(unlink("project-176.motus")) # double check

# Local auth Tags ---------------------------------------------------------
test_that("Tag data returned as expected - Proj 207", {
  skip_on_cran()
  skip_if_no_server()
  skip_if_no_auth()
  withr::local_file("project-207.motus")
  
  expect_message(tags <- withr::local_db_connection(
    tagme(projRecv = 207, new = TRUE))) %>%
    suppressMessages()
  expect_s4_class(tags, "SQLiteConnection")
  
  # Tables exists
  for(i in c("activity", "nodeData", "nodeDeps", "gps", 
             "hits", "runs", "batches", "deprecated", "recvDeps")) {
    expect_true(!!i %in% DBI::dbListTables(tags))
  }
  
  #nodeData
  expect_silent(a <- dplyr::tbl(tags, "nodeData") %>% dplyr::collect())
  expect_true(nrow(a) > 0)
  expect_true("nodeDataID" %in% names(a)) # check correct field name
  expect_true(all(c("nodets", "firmware", "solarVolt", "solarCurrent", 
                    "solarCurrentCumul", "lat", "lon") %in% names(a)))
  
  #tagDeps
  expect_silent(a <- dplyr::tbl(tags, "tagDeps") %>% dplyr::collect())
  expect_true(all(c("test", "age", "sex") %in% names(a)))
  expect_type(a$age, "character")
  expect_type(a$sex, "character")
  expect_type(a$test, "integer")
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags, "alltags"))
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags, "alltagsGPS"))
  
  #antDeps
  expect_silent(a <- dplyr::tbl(tags, "antDeps") %>% dplyr::collect())
  expect_true(all(c("antFreq") %in% names(a)))
  expect_type(a$antFreq, "double")
  
  #gps
  expect_silent(a <- dplyr::tbl(tags, "gps") %>% dplyr::collect())
  expect_true(all(c("lat_mean", "lon_mean", "n_fixes") %in% names(a)))
  
  #hits
  expect_silent(a <- dplyr::tbl(tags, "hits") %>% dplyr::collect())
  expect_true(all(c("validated") %in% names(a)))
  
  #deprecated
  expect_silent(a <- dplyr::tbl(tags, "deprecated") %>% 
                  dplyr::collect())
  expect_true(all(c("batchID", "batchFilter", "removed") %in% names(a)))
  expect_gt(nrow(a), 0)
  
  #recDeps
  expect_silent(a <- dplyr::tbl(tags, "recvDeps") %>% dplyr::collect())
  expect_true(all(c("stationName", "stationID") %in% names(a)))
  expect_type(a$stationName, "character")
  expect_type(a$stationID, "integer")
  expect_true(any(nchar(a$stationName) > 0))
  expect_true(any(a$stationID > 0))
})

test_that("Tag data returned as expected - Activity", {
  sample_auth()
  skip_if_no_server()
  unlink("project-176.motus") # For windows...
  withr::local_file("project-176.motus")
  
  expect_message(tags <- withr::local_db_connection(
    tagme(projRecv = 176, new = TRUE))) %>%
    suppressMessages() 
  
  #activity
  expect_silent(a <- dplyr::tbl(tags, "activity") %>% dplyr::collect())
  expect_true(nrow(a) > 0)
  expect_false(all(sapply(a, function(x) all(is.na(x))))) # Not all missing
  
  expect_type(a$ant, "character")   # All numeric/integer (except ant)
  for(i in names(a)[names(a) != "ant"]) {
    expect_true(is.numeric(a[, !!i][[1]]))
  }
})




# Local auth Receivers ----------------------------------------------------
test_that("Reciever data returned as expected", {
  skip_on_cran()
  skip_if_no_server()
  skip_if_no_auth()
  withr::local_file("SG-4002BBBK1580.motus")
  withr::local_options(list(motus.test.max = 1))
  
  # Create empty data
  expect_message(tags <- withr::local_db_connection(
    tagme(projRecv = "SG-4002BBBK1580", new = TRUE))) %>%
    suppressMessages()
  expect_s4_class(tags, "SQLiteConnection")
  
  # Tables exists
  for(i in c("activity", "nodeData", "nodeDeps", "gps", 
             "hits", "runs", "batches", "deprecated", "recvDeps",
             "activityAll", "gpsAll")) {
    expect_true(!!i %in% DBI::dbListTables(tags))
  }
  
  #activity
  expect_silent(a <- dplyr::tbl(tags, "activity") %>% dplyr::collect())
  #expect_true(nrow(a) > 0)
  #expect_false(all(sapply(a, function(x) all(is.na(x))))) # No all missing values
  
  expect_type(a$ant, "character")   # All numeric/integer (except ant)
  for(i in names(a)[names(a) != "ant"]) {
    expect_true(is.numeric(a[, !!i][[1]]))
  }
  
  #nodeData
  expect_silent(a <- dplyr::tbl(tags, "nodeData") %>% dplyr::collect())
  #expect_true(nrow(a) > 0)
  expect_true("nodeDataID" %in% names(a)) # check correct field name
  #expect_false(any(sapply(a, function(x) all(is.na(x))))) # No all missing values
  
  #tagDeps
  expect_silent(a <- dplyr::tbl(tags, "tagDeps") %>% dplyr::collect())
  expect_true(all(c("test", "age", "sex") %in% names(a)))
  expect_type(a$age, "character")
  expect_type(a$sex, "character")
  expect_type(a$test, "integer")
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags, "alltags"))
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags, "alltagsGPS"))
  
  #antDeps
  expect_silent(a <- dplyr::tbl(tags, "antDeps") %>% dplyr::collect())
  expect_true(all(c("antFreq") %in% names(a)))
  expect_type(a$antFreq, "double")
  expect_true(any(a$antFreq > 1))
  
  #deprecated
  expect_silent(a <- dplyr::tbl(tags, "deprecated") %>% dplyr::collect())
  expect_true(all(c("batchID", "batchFilter", "removed") %in% names(a)))
  expect_gt(nrow(a), 0)
  
  #recDeps
  expect_silent(a <- dplyr::tbl(tags, "recvDeps") %>% dplyr::collect())
  expect_true(all(c("stationName", "stationID") %in% names(a)))
  expect_type(a$stationName, "character")
  expect_type(a$stationID, "integer")
  expect_true(any(nchar(a$stationName) > 0))
  expect_true(any(a$stationID > 0))
  
  # Recv - activityAll/gpsAll  --------------
  # No problem downloading
  withr::local_options(list(motus.test.max = 1))
  expect_message(activityAll(tags), "activityAll: downloading all data") %>% 
    suppressMessages()
  #TODO: timeout? expect_message(gpsAll(tags), "gpsAll: checking for new data") %>% 
    #suppressMessages()
  
  # Expect data downloaded
  expect_gt(dplyr::tbl(tags, "activityAll") %>% dplyr::collect() %>% nrow(), 0)
  #expect_gt(dplyr::tbl(tags, "gpsAll") %>% dplyr::collect() %>% nrow(), 0)
})


# Proj - activityAll / gpsAll ----------------------------------------------
test_that("activityAll and gpsAll return for tag data", {
  skip_on_cran()
  skip_if_no_server()
  skip_if_no_auth()
  withr::local_file("project-4.motus")

  expect_message(tags <- withr::local_db_connection(
    tagme(projRecv = 4, new = TRUE))) %>%
    suppressMessages()
  expect_s4_class(tags, "SQLiteConnection")
  
  # Tables exists
  expect_true("activityAll" %in% DBI::dbListTables(tags))
  expect_true("gpsAll" %in% DBI::dbListTables(tags))
  
  # No problem downloading
  orig <- getOption("motus.test.max")
  options(motus.test.max = 3)
  expect_message(a <- activityAll(tags)) %>% suppressMessages()
  #TODO: timeout? expect_message(g <- gpsAll(tags)) %>% suppressMessages()
  options(motus.test.max = orig)
  
  # Expect data downloaded
  expect_gt(dplyr::tbl(a, "activityAll") %>% dplyr::collect() %>% nrow(), 0)
  #expect_gt(dplyr::tbl(a, "gpsAll") %>% dplyr::collect() %>% nrow(), 0)
})
