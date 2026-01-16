test_that("tagme() - Projects", {
  skip_if_no_server()
  sample_auth()
  unlink("project-176.motus") # Make sure nothing is here
  withr::local_file("project-176.motus")
  
  # New/Update
  expect_error(tagme(176), "If you \\*really\\* want to create")
  expect_silent(t <- withr::local_db_connection(tagme(176, new = TRUE, update = FALSE)))
  expect_true(file.exists("project-176.motus"))
  expect_equal(DBI::dbListTables(t), character())
  expect_s4_class(t, "SQLiteConnection")
  
  # Skip
  expect_message(t <- tagme(176, skipActivity = TRUE)) %>%
    suppressMessages()
  expect_s4_class(t, "SQLiteConnection")
  expect_equal(dplyr::tbl(t, "activity") %>% dplyr::count() %>% dplyr::pull(n), 0)
  
  expect_message(t <- tagme(176, skipActivity = FALSE)) %>%
    suppressMessages()
  expect_gt(dplyr::tbl(t, "activity") %>% dplyr::count() %>% dplyr::pull(n), 0)
})

test_that("tagme() - Receivers & skip nodeData as required", {
  skip_if_no_server()
  skip_if_no_auth()
  withr::local_file("SG-5113BBBK3139.motus")
  expect_message(t <- withr::local_db_connection(tagme("SG-5113BBBK3139", new = TRUE)),
                 "Reciever is not a SensorStation") %>%
    suppressMessages()
  expect_s4_class(t, "SQLiteConnection")
})

test_that("tagme() bulk", {
  skip_if_no_server()
  skip_if_no_auth()
  unlink("project-176.motus") # For windows...
  unlink(list.files(pattern = ".motus", full.names = TRUE)) # For windows...
  
  withr::local_options(motus.test.max = 5)
  withr::local_file(list("project-1.motus", "project-9.motus"))

  # Get starting databases
  withr::local_db_connection(tagme(1, update = FALSE, new = TRUE))
  withr::local_db_connection(tagme(9, update = FALSE, new = TRUE))
  
  # Bulk update - Expect skip activity
  expect_message(tagme(dir = ".", skipActivity = TRUE)) %>%
    suppressMessages()
  t <- withr::local_db_connection(tagme(9, update = FALSE))
  expect_equal(dplyr::tbl(t, "activity") %>% dplyr::count() %>% dplyr::pull(n), 0)
  
  # Bulk update - Expect don't skip activity
  expect_message(tagme(dir = ".", skipActivity = FALSE)) %>%
    suppressMessages()
  t <- withr::local_db_connection(tagme(9, update = FALSE))
  expect_gt(dplyr::tbl(t, "activity") %>% dplyr::count() %>% dplyr::pull(n), 0)
})

test_that("tagme() errors appropriately", {
  skip_on_cran()
  skip_if_no_server()
  sample_auth()
  
  expect_error(tagme(dir = "testing123"), "`dir` \\(testing123\\) does not exist")
  
  withr::local_file("project-10.motus")
  withr::local_file("CTT-5031194D3168.motus")
  expect_error(expect_message(
    withr::local_db_connection(tagme(projRecv = 10, new = TRUE)),
    "updateMotusDb"),
    "You do not have permission")
  
  expect_error(expect_message(
    withr::local_db_connection(tagme(projRecv = "CTT-5031194D3168",
                                     new = TRUE)),
    "updateMotusDb"),
    "Either") #...
})


test_that("tellme() - Projects", {
  skip_on_cran()
  skip_if_no_server()
  sample_auth()
  withr::local_file("project-176.motus")
  skip_if_no_file("project-176.motus", copy = TRUE)
  
  expect_silent(tagme(projRecv = 176, countOnly = TRUE)) %>%
    expect_s3_class("data.frame")
  
  expect_silent(tellme(projRecv = 176)) %>%
    expect_s3_class("data.frame")
})


test_that("tellme() - Receivers", {
  skip_on_cran()
  skip_if_no_server()
  skip_if_no_auth()
  unlink("SG-4002BBBK1580.motus") # For windows...
  
  withr::local_file("SG-4002BBBK1580.motus")
  expect_silent(tellme("SG-4002BBBK1580", new = TRUE)) %>%
    expect_s3_class("data.frame")
})
