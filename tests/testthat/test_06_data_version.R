context("checkDataVersion")

setup({
  # Copy the old version here for now
  file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
            "./project-176.motus")
})

teardown({
  # Remove old and new versions
  unlink("project-176.motus")
  unlink("project-176_v1.motus")
})

test_that("Database updates as expected", {
  if(packageVersion("motus") == 3) {
    sessionVariable(name = "userLogin", val = "motus.sample")
    sessionVariable(name = "userPassword", val = "motus.sample")
    
    expect_false(file.exists("project-176_v1.motus")) # No backup
    expect_error(tagme(176, new = FALSE, update = TRUE, rename = TRUE), NA)
    expect_true(file.exists("project-176_v1.motus"))  # Backup
    
    # Expect old and new to have different admInfo
    old <- DBI::dbConnect(RSQLite::SQLite(), dbname = "project-176_v1.motus")
    new <- DBI::dbConnect(RSQLite::SQLite(), dbname = "project-176.motus")
    expect_named(dplyr::tbl(old, "admInfo") %>% dplyr::collect(), 
                 expected = c("key", "value"))
    expect_named(dplyr::tbl(new, "admInfo") %>% dplyr::collect(), 
                 expected = c("db_version", "data_version"))  # New version
    
    expect_equal(dplyr::tbl(old, "tags") %>% dplyr::collect(),
                 dplyr::tbl(new, "tags") %>% dplyr::collect())
    
    expect_equal(dplyr::tbl(old, "activity") %>% dplyr::collect() 
                 %>% dplyr::mutate(ant = as.character(.data$ant)),
                 dplyr::tbl(new, "activity") %>% dplyr::collect())
    
    expect_equal(dplyr::tbl(old, "hits") %>% dplyr::collect(),
                 dplyr::tbl(new, "hits") %>% dplyr::collect())
    
    expect_equal(dplyr::tbl(old, "runs") %>% dplyr::collect() %>% 
                   dplyr::mutate(ant = as.character(.data$ant)),
                 dplyr::tbl(new, "runs") %>% dplyr::collect() %>% 
                   dplyr::select(-nodeNum))
  }
})

test_that("Update fails if backup present", {
  if(packageVersion("motus") == 3 && file.exists("project-176_v1.motus")) {
    unlink("project-176.motus") 
    file.copy("project-176_v1.motus", "project-176.motus")
    
    expect_error(expect_message(
      tagme(176, new = FALSE, update = TRUE, rename = TRUE), "DATABASE UPDATE"),
      "_v1.motus already exists")
  }
})