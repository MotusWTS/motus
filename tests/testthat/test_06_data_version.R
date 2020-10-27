context("Data version updates correctly")

setup({
  unlink("project-176.motus")
  unlink("project-176_v1.motus")
  unlink("SG-3115BBBK1127.motus")
  unlink("SG-3115BBBK1127_v1.motus")
})

teardown({
  # Remove old and new versions
  unlink("project-176.motus")
  unlink("project-176_v1.motus")
  unlink("SG-3115BBBK1127.motus")
  unlink("SG-3115BBBK1127_v1.motus")
})

test_that("Database updates as expected (proj) - new = TRUE", {
  if(utils::packageVersion("motus") >= 3) {
    sample_auth()
    
    expect_false(file.exists("project-176_v1.motus")) # No backup
    file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
              "./project-176.motus")
    expect_warning(t <- tagme(176, new = TRUE, update = TRUE, rename = TRUE), 
                   "already exists")
    expect_true(file.exists("project-176_v1.motus"))  # Backup
    DBI::dbDisconnect(t$con)
    rm(t)
    gc()
    unlink("project-176.motus")
    unlink("project-176_v1.motus")

    # With forceMeta = TRUE
    expect_false(file.exists("project-176_v1.motus")) # No backup
    file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
              "./project-176.motus")
    expect_warning(expect_message(t <- tagme(176, new = TRUE, 
                                             update = TRUE, forceMeta = TRUE,
                                             rename = TRUE)), 
                   "already exists")
    expect_true(file.exists("project-176_v1.motus"))  # Backup
    DBI::dbDisconnect(t$con)
    rm(t)
    gc()
    unlink("project-176.motus")
    unlink("project-176_v1.motus")
  }
})

test_that("Database updates as expected (proj) - new = FALSE", {
  skip_if_not(utils::packageVersion("motus") >= 3)
  
  sample_auth()
  
  expect_false(file.exists("project-176_v1.motus")) # No backup
  file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
            "./project-176.motus")
  expect_message(t <- tagme(176, new = FALSE, update = TRUE, rename = TRUE))
  expect_true(file.exists("project-176_v1.motus"))  # Backup
  DBI::dbDisconnect(t$con)
  
  old <- DBI::dbConnect(RSQLite::SQLite(), dbname = "project-176_v1.motus")
  new <- DBI::dbConnect(RSQLite::SQLite(), dbname = "project-176.motus")
  
  # Expect old and new to have different admInfo 
  expect_named(dplyr::tbl(old, "admInfo") %>% dplyr::collect(), 
               expected = c("key", "value"))
  expect_named(dplyr::tbl(new, "admInfo") %>% dplyr::collect(), 
               expected = c("db_version", "data_version"))  # New version
  
  expect_true(all(sort(DBI::dbListFields(old, "activity")) %in%
                    sort(DBI::dbListFields(new, "activity"))))
              
  expect_gt(DBI::dbGetQuery(new, "SELECT * FROM activity") %>% nrow(), 0)
  expect_gt(DBI::dbGetQuery(new, "SELECT * FROM hits") %>% nrow(), 0)
  expect_gt(DBI::dbGetQuery(new, "SELECT * FROM runs") %>% nrow(), 0)
  
  DBI::dbDisconnect(old)
  DBI::dbDisconnect(new)

})

test_that("Update fails if backup present (proj)", {
  skip_if_not(utils::packageVersion("motus") >= 3 && 
                file.exists("project-176_v1.motus"))
    
  unlink("project-176.motus") 
  file.copy("project-176_v1.motus", "project-176.motus")
  sample_auth()
  
  expect_error(expect_message(
    tagme(176, new = FALSE, update = TRUE, rename = TRUE), "DATABASE UPDATE"),
    "_v1.motus already exists")
  
})

test_that("Database updates as expected (receivers)", {
  skip_if_not(utils::packageVersion("motus") >= 3 && have_auth())
  
  local_auth()
  
  # Create dummy version 1
  tags <- tagme("SG-3115BBBK1127", new = TRUE, update = TRUE)
  DBI::dbExecute(tags$con, "UPDATE admInfo set data_version = 1")
  DBI::dbDisconnect(tags$con)
  
  expect_false(file.exists("SG-3115BBBK1127_v1.motus")) # No backup
  expect_warning(t <- tagme("SG-3115BBBK1127", new = TRUE, 
                            update = TRUE, rename = TRUE), 
                 "already exists")
  expect_true(file.exists("SG-3115BBBK1127_v1.motus"))  # Backup
  DBI::dbDisconnect(t$con)
  rm(t)
  gc()
  unlink("SG-3115BBBK1127.motus")
  unlink("SG-3115BBBK1127_v1.motus")
  
  # Create dummy version 1
  orig <- options(motus.test.max = 30)
  tags <- tagme("SG-3115BBBK1127", new = TRUE, update = TRUE)
  DBI::dbExecute(tags$con, "UPDATE admInfo set data_version = 1")
  DBI::dbDisconnect(tags$con)
  
  expect_false(file.exists("SG-3115BBBK1127_v1.motus")) # No backup
  expect_error(t <- tagme("SG-3115BBBK1127", new = FALSE, update = TRUE, rename = TRUE), NA)
  expect_true(file.exists("SG-3115BBBK1127_v1.motus"))  # Backup
  DBI::dbDisconnect(t$con)
  
  # Expect data
  new <- DBI::dbConnect(RSQLite::SQLite(), dbname = "SG-3115BBBK1127.motus")
  
  expect_gt(DBI::dbGetQuery(new, "SELECT * FROM activity") %>% nrow(), 0)
  expect_gt(DBI::dbGetQuery(new, "SELECT * FROM hits") %>% nrow(), 0)
  expect_gt(DBI::dbGetQuery(new, "SELECT * FROM runs") %>% nrow(), 0)
  
  DBI::dbDisconnect(new)
  options(orig)

})

test_that("Update fails if backup present (receivers)", {
  
  skip_if_not(have_auth() && 
                utils::packageVersion("motus") >= 3 && 
                file.exists("SG-3115BBBK1127_v1.motus"))
  
  local_auth()
  unlink("SG-3115BBBK1127.motus") 
  file.copy("SG-3115BBBK1127_v1.motus", "SG-3115BBBK1127.motus")
  
  expect_error(expect_message(
    t <- tagme("SG-3115BBBK1127", new = FALSE, update = TRUE, rename = TRUE), 
    "DATABASE UPDATE"),
    "_v1.motus already exists")

  unlink("SG-3115BBBK1127.motus")
  unlink("SG-3115BBBK1127_v1.motus")
})
