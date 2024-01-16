test_that("Proj - DB updates - new = TRUE", {
  sample_auth()
  skip_if_no_server()
  withr::local_file("project-176.motus")
  withr::local_file("project-176_v1.motus")
  
  # Get old version
  file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
            "./project-176.motus")
  
  expect_false(file.exists("project-176_v1.motus")) # No backup
  expect_warning(
    withr::local_db_connection(
      t <- tagme(176, new = TRUE, update = TRUE, rename = TRUE)), 
    "already exists") %>%
    suppressMessages()
  expect_true(file.exists("project-176_v1.motus"))  # Backup
})

test_that("Proj - DB updates - forceMeta", {
  sample_auth()
  skip_if_no_server()
  withr::local_file("project-176.motus")
  withr::local_file("project-176_v1.motus")
  
  # Get old version
  file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
            "./project-176.motus")
  
  expect_false(file.exists("project-176_v1.motus")) # No backup
  expect_warning(expect_message(
    withr::local_db_connection(
      t <- tagme(176, new = TRUE, update = TRUE, forceMeta = TRUE, rename = TRUE))), 
    "already exists") %>%
    suppressMessages()
  expect_true(file.exists("project-176_v1.motus"))  # Backup
})

test_that("Proj - DB updates - new = FALSE", {
  sample_auth()
  skip_if_no_server()
  withr::local_file("project-176.motus")
  withr::local_file("project-176_v1.motus")
  
  # Get old version
  file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
            "./project-176.motus")
  
  expect_false(file.exists("project-176_v1.motus")) # No backup
  expect_message(
    withr::local_db_connection(
      t <- tagme(176, new = FALSE, update = TRUE, rename = TRUE))) %>%
    suppressMessages()
  expect_true(file.exists("project-176_v1.motus"))  # Backup

  old <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), dbname = "project-176_v1.motus"))
  new <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), dbname = "project-176.motus"))
  
  # Expect old and new to have different admInfo 
  expect_named(dplyr::tbl(old, "admInfo") %>% dplyr::collect(), 
               expected = c("key", "value"))
  expect_named(dplyr::tbl(new, "admInfo") %>% dplyr::collect(), 
               expected = c("db_version", "data_version"))  # New version
  
  expect_true(all(sort(DBI::dbListFields(old, "activity")) %in%
                    sort(DBI::dbListFields(new, "activity"))))
              
  expect_gt(DBI_Query(new, "SELECT * FROM activity") %>% nrow(), 0)
  expect_gt(DBI_Query(new, "SELECT * FROM hits") %>% nrow(), 0)
  expect_gt(DBI_Query(new, "SELECT * FROM runs") %>% nrow(), 0)
})

test_that("Proj - Update fails if backup present", {
  sample_auth()
  skip_if_no_server()
  withr::local_file("project-176_v1.motus")
  withr::local_file("project-176.motus")
  file.create("project-176_v1.motus")
  
  # Get old version
  file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
            "./project-176.motus")
  
  expect_error(
    expect_message(
      withr::local_db_connection(
        tagme(176, new = FALSE, update = TRUE, rename = TRUE), "DATABASE UPDATE")),
    "_v1.motus already exists") %>%
    suppressMessages()
})

test_that("Recv - DB updates - 2", {
  skip_if_no_server()
  skip_if_no_auth()
  withr::local_file("SG-3115BBBK1127.motus")
  withr::local_file("SG-3115BBBK1127_v1.motus")
  
  # Create dummy version 1 - more data
  withr::local_options(list(motus.test.max = 30))
  tags <- withr::local_db_connection(
    tagme("SG-3115BBBK1127", new = TRUE, update = TRUE)) %>%
    suppressMessages()
  DBI_Execute(tags, "UPDATE admInfo set data_version = 1")
  
  expect_false(file.exists("SG-3115BBBK1127_v1.motus")) # No backup
  expect_message(
    t <- withr::local_db_connection(
      tagme("SG-3115BBBK1127", new = FALSE, update = TRUE, rename = TRUE))) %>%
    suppressMessages()
  expect_true(file.exists("SG-3115BBBK1127_v1.motus"))  # Backup
  
  # Expect data
  new <- withr::local_db_connection(
    DBI::dbConnect(RSQLite::SQLite(), dbname = "SG-3115BBBK1127.motus"))
  
  expect_gt(DBI_Query(new, "SELECT * FROM activity") %>% nrow(), 0)
  expect_gt(DBI_Query(new, "SELECT * FROM hits") %>% nrow(), 0)
  expect_gt(DBI_Query(new, "SELECT * FROM runs") %>% nrow(), 0)
})

test_that("Recv - Update fails if backup present", {
  skip_if_no_auth()
  skip_if_no_server()
  
  withr::local_file("SG-3115BBBK1127_v1.motus")
  withr::local_file("SG-3115BBBK1127.motus")
  file.create("SG-3115BBBK1127_v1.motus")
  
  # Get old version
  file.copy(system.file("extdata", "project-176_v1.motus", package = "motus"),
            "./SG-3115BBBK1127.motus")
  
  expect_error(expect_message(
    t <- withr::local_db_connection(
      tagme("SG-3115BBBK1127", new = FALSE, update = TRUE, rename = TRUE)), 
    "DATABASE UPDATE"),
    "_v1.motus already exists") %>%
    suppressMessages()
})
