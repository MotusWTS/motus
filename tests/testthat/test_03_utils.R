context("Utility functions")

teardown(unlink("project-176.motus"))

test_that("checkVersion and updateMotusDb run and return messages as expected", {
  # Prep db files
  shorebirds_sql <- tagme(176, update = FALSE, 
                          dir = system.file("extdata", package = "motus"))
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".", 
            overwrite = TRUE)
  test_sql <- tagme(176, update = FALSE)
  # DBI::dbExecute(test_sql$con, paste0("UPDATE admInfo set value = ",
  #                                     "'2017-12-01 00:00:00' ",
  #                                     "where key = 'db_version'"))
  
  # Normal database
  expect_message(checkVersion(shorebirds_sql), 
                 "Your motus sqlite file is up-to-date with the package.")
  expect_silent(updateMotusDb(shorebirds_sql))
  
  # Old version database
  # expect_message(checkVersion(test_sql), 
  #                "Your motus sqlite file version does not match the package.")
  # expect_message(updateMotusDb(test_sql, test_sql), 
  #                "updateMotusDb started \\([0-9]{1,3} versions updates\\)")
  
  # After update
  # expect_silent(updateMotusDb(test_sql, test_sql))
  # expect_equal(dplyr::tbl(test_sql, "admInfo") %>% dplyr::pull(value), 
  #              dplyr::tbl(shorebirds_sql, "admInfo") %>% dplyr::pull(value))
  # expect_length(dplyr::tbl(test_sql, "admInfo") %>% dplyr::pull(value), 1)
  
  # No admInfo Table
  DBI::dbRemoveTable(test_sql$con, "admInfo")
  
  expect_message(checkVersion(test_sql), 
                 "The admInfo table has not yet been created in your motus sqlite file.")
  # expect_message(updateMotusDb(test_sql, test_sql), 
  #                "updateMotusDb started \\([0-9]{1,3} versions updates\\)")
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
