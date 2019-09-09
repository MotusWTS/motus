context("checkDataVersion")
teardown(unlink("test.motus"))
teardown(unlink("test_v1.motus"))

test_that("checkDataVersion archives old files", {
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  rv <- dplyr::src_sqlite("test.motus", create = TRUE)
  
  expect_message(rv <- checkDataVersion(rv, dbname = "test.motus", rename = TRUE),
                 "DATABASE UPDATE \\(data version 1 -> 2\\)") %>%
    expect_is("src_SQLiteConnection")
  expect_true(file.exists("test_v1.motus"))
  
  expect_error(expect_message(
    checkDataVersion(rv, dbname = "test.motus", rename = TRUE),
    "DATABASE UPDATE \\(data version 1 -> 2\\)"), "already exists")
})