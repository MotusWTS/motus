test_that("checkVersion and updateMotusDb run and return messages as expected", {
  
  tags <- tagmeSample()
  
  # Normal database
  expect_message(checkVersion(tags), 
                 "Your motus sqlite file is up-to-date with the package.") %>%
    suppressMessages()
  expect_silent(updateMotusDb(tags))
  
  # No admInfo Table
  DBI::dbRemoveTable(tags, "admInfo")
  
  expect_message(
    checkVersion(tags), 
    "The admInfo table has not yet been created in your motus sqlite file.") %>%
    suppressMessages()
})

test_that("is_proj identifies projects vs. receivers", {
  expect_true(is_proj(176))
  expect_true(is_proj(9999))
  expect_false(is_proj("SG-3115BBBK0782"))
})

test_that("get_projRecv pulls project name", {
  d <- system.file("extdata", package = "motus")
  
  expect_equal(get_projRecv(tagme(176, update = FALSE, dir = d)), 176)
  expect_error(get_projRecv("hello"), "src must be a SQLite")
  
  skip_if_no_auth()
  skip_if_no_file("SG-3115BBBK0782.motus")
  expect_equal(get_projRecv(tagme("SG-3115BBBK0782", update = FALSE, dir = d)),
               "SG-3115BBBK0782")
})
