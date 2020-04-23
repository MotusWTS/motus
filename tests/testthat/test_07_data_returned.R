context("Data returned")
setup({
  unlink("project-207.motus")
})

teardown({
  unlink("project-207.motus")
})

test_that("Data returned as expected", {
  skip_on_cran()
  skip_if_no_auth()
  
  orig <- getOption("motus.test.max")
  options(motus.test.max = 60)
  
  expect_message(tags <- tagme(projRecv = 207, new = TRUE, update = TRUE)) %>%
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
  expect_true(nrow(a) > 0)
  expect_true("nodeDataID" %in% names(a)) # check correct field name
  expect_false(any(sapply(a, function(x) all(is.na(x))))) # No all missing values
  
  #tagDeps
  expect_silent(a <- dplyr::tbl(tags$con, "tagDeps") %>% dplyr::collect())
  expect_true("test" %in% names(a))
  expect_is(a$test, "integer")
  expect_true("tagDeployTest" %in% DBI::dbListFields(tags$con, "alltags"))
  
  
  options(motus.test.max = orig)
})