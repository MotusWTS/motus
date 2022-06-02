teardown(unlink("project-176.motus"))

test_that("checkVersion and updateMotusDb run and return messages as expected", {
  
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  tags <- tagme(176, update = FALSE)
  
  # Normal database
  expect_message(checkVersion(tags), 
                 "Your motus sqlite file is up-to-date with the package.")
  expect_silent(updateMotusDb(tags))
  
  # No admInfo Table
  DBI::dbRemoveTable(tags$con, "admInfo")
  
  expect_message(checkVersion(tags), 
                 "The admInfo table has not yet been created in your motus sqlite file.")
})

test_that("is_proj identifies projects vs. receivers", {
  expect_true(is_proj(176))
  expect_true(is_proj(9999))
  expect_false(is_proj("SG-3115BBBK0782"))
})

test_that("get_projRecv pulls project name", {
  d <- system.file("extdata", package = "motus")
  
  expect_equal(get_projRecv(tagme(176, update = FALSE, dir = d)), 176)
  expect_error(get_projRecv("hello"), "src is not a dplyr::src_sql object")
  
  skip_if_no_auth()
  skip_if_no_file(system.file("extdata", "SG-3115BBBK0782.motus", package = "motus"))
  expect_equal(get_projRecv(tagme("SG-3115BBBK0782", update = FALSE, dir = d)),
               "SG-3115BBBK0782")
  
})
