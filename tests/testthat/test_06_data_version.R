context("checkDataVersion")
teardown(unlink("test.motus"))
teardown(unlink("test_v1.motus"))

test_that("checkDataVersion archives old files", {
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  rv <- dplyr::src_sqlite("test.motus", create = TRUE)
  
  expect_silent(checkDataVersion(rv, dbname = "test.motus", rename = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  expect_true(file.exists("test_v1.motus"))
  
  expect_error(checkDataVersion(rv, dbname = "test.motus", rename = TRUE),
               "already exists")
})