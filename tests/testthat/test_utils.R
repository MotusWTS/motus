context("Utility functions")


test_that("checkVersion and updateMotusDb run and return messages as expected", {
  # Prep db files
  shorebirds_sql <- tagme(176, update = FALSE, 
                          dir = system.file("extdata", package = "motus"))
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".", 
            overwrite = TRUE)
  test_sql <- tagme(176, update = FALSE)
  DBI::dbExecute(test_sql$con, paste0("UPDATE admInfo set value = ",
                                      "'2017-12-01 00:00:00' ",
                                      "where key = 'db_version'"))
  
  # Normal database
  expect_message(checkVersion(shorebirds_sql), 
                 "Your motus sqlite file is up-to-date with the package.")
  expect_silent(updateMotusDb(shorebirds_sql, shorebirds_sql))
  
  # Old version database
  expect_message(checkVersion(test_sql), 
                 "Your motus sqlite file version does not match the package.")
  expect_message(updateMotusDb(test_sql, test_sql), 
                 "updateMotusDb started \\([0-9]{1,3} versions updates\\)")
  
  # After update
  expect_silent(updateMotusDb(test_sql, test_sql))
  expect_equal(dplyr::tbl(test_sql, "admInfo") %>% dplyr::pull(value), 
               dplyr::tbl(shorebirds_sql, "admInfo") %>% dplyr::pull(value))
  expect_length(dplyr::tbl(test_sql, "admInfo") %>% dplyr::pull(value), 1)
  
  # No admInfo Table
  dplyr::db_drop_table(test_sql$con, "admInfo")
  
  expect_message(checkVersion(test_sql), 
                 "The admInfo table has not yet been created in your motus sqlite file.")
  expect_message(updateMotusDb(test_sql, test_sql), 
                 "updateMotusDb started \\([0-9]{1,3} versions updates\\)")
  
  # Clean up
  file.remove("./project-176.motus")
})
