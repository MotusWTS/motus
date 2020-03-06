context("Test Server Access")

test_that("tagme() errors appropriately", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_travis()
  
  if(file.exists("project-10.motus")) unlink("project-10.motus")
  if(file.exists("SG-3021RPI2BBB8.motus")) unlink("SG-3021RPI2BBB8.motus")
  
  sample_auth()
  
  expect_error(expect_message(tagme(projRecv = 10, new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "You do not have permission")
  
  expect_error(expect_message(tagme(projRecv = "SG-3021RPI2BBB8", 
                                    new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "don't have permission")
  
  if(file.exists("project-10.motus")) unlink("project-10.motus")
  if(file.exists("SG-3021RPI2BBB8.motus")) unlink("SG-3021RPI2BBB8.motus")
})

test_that("tagme() downloads data - Projects", {
  skip_on_cran()
  skip_on_appveyor()
  
  if(file.exists("project-176.motus")) unlink("project-176.motus")
  
  sample_auth()
  
  expect_message(tags <- tagme(projRecv = 176, new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Table exists
  expect_silent(a <- dplyr::tbl(tags, "activity") %>% dplyr::collect())
  expect_silent(dplyr::tbl(tags, "nodeData"))
  expect_silent(dplyr::tbl(tags, "nodeDeps"))
  
  # No all missing values
  expect_false(any(sapply(a, function(x) all(is.na(x)))))
  
  # All numeric/integer (except ant)
  expect_is(a$ant, "character")
  for(i in names(a)[names(a) != "ant"]) {
    expect_is(a[, !!i][[1]], c("integer", "numeric"))
  }
})

test_that("Receivers download - Receivers", {
  skip_on_cran()
  skip_on_appveyor()
  skip_if_no_auth()
  
  if(file.exists("SG-3115BBBK1127.motus")) unlink("SG-3115BBBK1127.motus")
  expect_message(tagme("SG-3115BBBK1127", new = TRUE, update = TRUE)) %>%
    expect_s3_class("src_sql")
  if(file.exists("SG-3115BBBK1127.motus")) unlink("SG-3115BBBK1127.motus")
})

test_that("tagme with countOnly (tellme) - Projects", {
  skip("Temp")
  skip_on_cran()
  
  sample_auth()
  
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  
  expect_silent(tagme(projRecv = 176, new = FALSE, 
                      update = TRUE, countOnly = TRUE)) %>%
    expect_is("data.frame")
  
  expect_silent(tellme(projRecv = 176, new = FALSE)) %>%
    expect_is("data.frame")
  
  if(file.exists("project-176.motus")) unlink("project-176.motus")
})

test_that("tagme with countOnly (tellme) - Receivers", {
  skip("Temp")
  skip_on_cran()
  skip_if_no_auth()
  
  if(file.exists("SG-3115BBBK1127.motus")) unlink("SG-3115BBBK1127.motus")
  expect_silent(tellme("SG-3115BBBK1127", new = TRUE)) %>%
    expect_is("data.frame")
  if(file.exists("SG-3115BBBK1127.motus")) unlink("SG-3115BBBK1127.motus")
})

test_that("srvQuery handles time out graciously", {
  
  sample_auth()
  
  # https://stackoverflow.com/questions/100841/artificially-create-a-connection-timeout-error
  expect_message(
    expect_error(srvQuery(API = motus_vars$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT, 
                          params = list(projectID = 176),
                          url = "10.255.255.1", timeout = 1),
                 "The server is not responding"),
    "The server did not respond within 1s. Trying again...")
})

test_that("srvAuth handles errors informatively", {
  motusLogout()
  sessionVariable(name = "userLogin", val = "motus.samp")
  sessionVariable(name = "userPassword", val = "motus.samp")
  
  expect_error(srvAuth(), "Authentication failed")
})
