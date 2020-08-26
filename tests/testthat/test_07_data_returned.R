context("Data returned")
setup({
  unlink("project-207.motus")
  unlink("SG-3115BBBK1127.motus")
})

teardown({
  unlink("project-207.motus")
  unlink("SG-3115BBBK1127.motus")
})

test_that("Data returned as expected", {
  skip_on_cran()
  skip_if_no_auth()
  
  orig <- getOption("motus.test.max")
  options(motus.test.max = 60)
  
  expect_message(tags <- tagme(projRecv = 207, new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Tables exists
  for(i in c("activity", "nodeData", "nodeDeps", "gps", 
             "hits", "runs", "batches")) {
    expect_true(!!i %in% DBI::dbListTables(tags$con))
  }
  
  #activity
  expect_silent(a <- dplyr::tbl(tags$con, "activity") %>% dplyr::collect())
  expect_true(nrow(a) > 0)
  expect_false(any(sapply(a, function(x) all(is.na(x))))) # No all missing values
  
  expect_is(a$ant, "character")   # All numeric/integer (except ant)
  for(i in names(a)[names(a) != "ant"]) {
    expect_is(a[, !!i][[1]], c("integer", "numeric"))
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
  
  options(motus.test.max = orig)
})

test_that("Data returned as expected", {
  skip_on_cran()
  skip_if_no_auth()
  
  orig <- getOption("motus.test.max")
  options(motus.test.max = 60)
  
  expect_message(tags <- tagme(projRecv = "SG-3115BBBK0782", new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Tables exists
  expect_true("activity" %in% DBI::dbListTables(tags$con))
  expect_true("nodeData" %in% DBI::dbListTables(tags$con))
  expect_true("nodeDeps" %in% DBI::dbListTables(tags$con))
  
  #activity
  expect_silent(a <- dplyr::tbl(tags$con, "activity") %>% dplyr::collect())
  expect_true(nrow(a) > 0)
  expect_false(any(sapply(a, function(x) all(is.na(x))))) # No all missing values
  
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
  expect_is(a$age, "character")
  expect_is(a$sex, "character")
  expect_is(a$test, "integer")
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags$con, "alltags"))
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags$con, "alltagsGPS"))
  
  #antDeps
  expect_silent(a <- dplyr::tbl(tags$con, "antDeps") %>% dplyr::collect())
  expect_true(all(c("antFreq") %in% names(a)))
  expect_is(a$antFreq, "numeric")
  expect_true(any(a$antFreq > 1))
  
  options(motus.test.max = orig)
})