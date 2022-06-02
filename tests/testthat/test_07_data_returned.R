context("Data returned")

# Local auth Tags ---------------------------------------------------------
test_that("Tag data returned as expected", {
  skip_on_cran()
  skip_if_no_auth()
  
  expect_message(tags <- tagme(projRecv = 207, new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Tables exists
  for(i in c("activity", "nodeData", "nodeDeps", "gps", 
             "hits", "runs", "batches", "deprecated", "recvDeps")) {
    expect_true(!!i %in% DBI::dbListTables(tags$con))
  }
  
  #nodeData
  expect_silent(a <- dplyr::tbl(tags$con, "nodeData") %>% dplyr::collect())
  expect_true(nrow(a) > 0)
  expect_true("nodeDataID" %in% names(a)) # check correct field name
  expect_true(all(c("nodets", "firmware", "solarVolt", "solarCurrent", 
                    "solarCurrentCumul", "lat", "lon") %in% names(a)))
  
  #tagDeps
  expect_silent(a <- dplyr::tbl(tags$con, "tagDeps") %>% dplyr::collect())
  expect_true(all(c("test", "age", "sex") %in% names(a)))
  expect_is(a$age, "character")
  expect_is(a$sex, "character")
  expect_is(a$test, "integer")
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags$con, "alltags"))
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags$con, "alltagsGPS"))
  
  #antDeps
  expect_silent(a <- dplyr::tbl(tags$con, "antDeps") %>% dplyr::collect())
  expect_true(all(c("antFreq") %in% names(a)))
  expect_is(a$antFreq, "numeric")
  
  #gps
  expect_silent(a <- dplyr::tbl(tags$con, "gps") %>% dplyr::collect())
  expect_true(all(c("lat_mean", "lon_mean", "n_fixes") %in% names(a)))
  
  #hits
  expect_silent(a <- dplyr::tbl(tags$con, "hits") %>% dplyr::collect())
  expect_true(all(c("validated") %in% names(a)))
  
  #deprecated
  expect_silent(a <- dplyr::tbl(tags$con, "deprecated") %>% 
                  dplyr::collect())
  expect_true(all(c("batchID", "batchFilter", "removed") %in% names(a)))
  expect_gt(nrow(a), 0)
  
  #recDeps
  expect_silent(a <- dplyr::tbl(tags$con, "recvDeps") %>% dplyr::collect())
  expect_true(all(c("stationName", "stationID") %in% names(a)))
  expect_is(a$stationName, "character")
  expect_is(a$stationID, "integer")
  expect_true(any(nchar(a$stationName) > 0))
  expect_true(any(a$stationID > 0))
  
  disconnect(tags$con)
  unlink("project-207.motus")
  
  expect_message(tags <- tagme(projRecv = 1, new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  #activity
  expect_silent(a <- dplyr::tbl(tags$con, "activity") %>% dplyr::collect())
  expect_true(nrow(a) > 0)
  expect_false(all(sapply(a, function(x) all(is.na(x))))) # Not all missing
  
  expect_is(a$ant, "character")   # All numeric/integer (except ant)
  for(i in names(a)[names(a) != "ant"]) {
    expect_is(a[, !!i][[1]], c("integer", "numeric"))
  }
  
  disconnect(tags$con)
  unlink("project-1.motus")
})




# Local auth Receivers ----------------------------------------------------
test_that("Reciever data returned as expected", {
  skip_on_cran()
  skip_if_no_auth()
  
  orig <- getOption("motus.test.max")
  options(motus.test.max = 60)
  unlink("SG-3115BBBK0782.motus")
  
  expect_message(tags <- tagme(projRecv = "SG-3115BBBK0782", 
                               new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Tables exists
  for(i in c("activity", "nodeData", "nodeDeps", "gps", 
             "hits", "runs", "batches", "deprecated", "recvDeps")) {
    expect_true(!!i %in% DBI::dbListTables(tags$con))
  }
  
  #activity
  expect_silent(a <- dplyr::tbl(tags$con, "activity") %>% dplyr::collect())
  expect_true(nrow(a) > 0)
  expect_false(all(sapply(a, function(x) all(is.na(x))))) # No all missing values
  
  expect_is(a$ant, "character")   # All numeric/integer (except ant)
  for(i in names(a)[names(a) != "ant"]) {
    expect_is(a[, !!i][[1]], c("integer", "numeric"))
  }
  
  #nodeData
  expect_silent(a <- dplyr::tbl(tags$con, "nodeData") %>% dplyr::collect())
  #expect_true(nrow(a) > 0)
  expect_true("nodeDataID" %in% names(a)) # check correct field name
  #expect_false(any(sapply(a, function(x) all(is.na(x))))) # No all missing values
  
  #tagDeps
  expect_silent(a <- dplyr::tbl(tags$con, "tagDeps") %>% dplyr::collect())
  expect_true(all(c("test", "age", "sex") %in% names(a)))
  expect_type(a$age, "character")
  expect_type(a$sex, "character")
  expect_type(a$test, "integer")
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags$con, "alltags"))
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags$con, "alltagsGPS"))
  
  #antDeps
  expect_silent(a <- dplyr::tbl(tags$con, "antDeps") %>% dplyr::collect())
  expect_true(all(c("antFreq") %in% names(a)))
  expect_type(a$antFreq, "double")
  expect_true(any(a$antFreq > 1))
  
  #deprecated
  expect_silent(a <- dplyr::tbl(tags$con, "deprecated") %>% dplyr::collect())
  expect_true(all(c("batchID", "batchFilter", "removed") %in% names(a)))
  expect_gt(nrow(a), 0)
  
  #recDeps
  expect_silent(a <- dplyr::tbl(tags$con, "recvDeps") %>% dplyr::collect())
  expect_true(all(c("stationName", "stationID") %in% names(a)))
  expect_is(a$stationName, "character")
  expect_is(a$stationID, "integer")
  expect_true(any(nchar(a$stationName) > 0))
  expect_true(any(a$stationID > 0))
  
  options(motus.test.max = orig)
  disconnect(tags$con)
  unlink("SG-3115BBBK0782.motus")
})


# activityAll / gpsAll ----------------------------------------------------
test_that("activityAll and gpsAll return for tag data", {
  skip_on_cran()
  skip_if_no_auth()
  
  unlink("project-4.motus")
  expect_message(tags <- tagme(projRecv = 4, new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Tables exists
  expect_true("activityAll" %in% DBI::dbListTables(tags$con))
  expect_true("gpsAll" %in% DBI::dbListTables(tags$con))
  
  # No problem downloading
  orig <- getOption("motus.test.max")
  options(motus.test.max = 3)
  expect_message(a <- activityAll(tags))
  expect_message(g <- gpsAll(tags))
  options(motus.test.max = orig)
  
  # Expect data downloaded
  expect_gt(dplyr::tbl(a, "activityAll") %>% dplyr::collect() %>% nrow(), 0)
  expect_gt(dplyr::tbl(a, "gpsAll") %>% dplyr::collect() %>% nrow(), 0)
  
  disconnect(tags$con)
  unlink("project-4.motus")
})

test_that("activityAll and gpsAll return for receiver data", {
  skip_on_cran()
  skip_if_no_auth()
  
  unlink("SG-3115BBBK0782.motus")
  expect_message(tags <- tagme(projRecv = "SG-3115BBBK0782", 
                               new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Tables exists
  expect_true("activityAll" %in% DBI::dbListTables(tags$con))
  expect_true("gpsAll" %in% DBI::dbListTables(tags$con))
  
  # No problem downloading
  orig <- getOption("motus.test.max")
  options(motus.test.max = 3)
  expect_message(activityAll(tags))
  expect_message(gpsAll(tags))
  options(motus.test.max = orig)
  
  # Expect data downloaded
  expect_gt(dplyr::tbl(tags, "activityAll") %>% dplyr::collect() %>% nrow(), 0)
  expect_gt(dplyr::tbl(tags, "gpsAll") %>% dplyr::collect() %>% nrow(), 0)
  disconnect(tags$con)
  unlink("SG-3115BBBK0782.motus")
})