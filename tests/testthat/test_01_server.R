context("Test Server Access")

test_that("tagme() errors appropriately", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_travis()
  
  unlink("project-10.motus")
  unlink("CTT-5031194D3168")
  
  sample_auth()
  
  expect_error(expect_message(tagme(projRecv = 10, new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "You do not have permission")
  
  expect_error(expect_message(tagme(projRecv = "CTT-5031194D3168", 
                                    new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "Either") #...
  
  unlink("project-10.motus")
  unlink("CTT-5031194D3168.motus")
})

test_that("tagme() downloads data - Projects", {
  skip_on_cran()
  skip_on_appveyor()
  
  unlink("project-176.motus")
  
  sample_auth()
  
  expect_message(tags <- tagme(projRecv = 176, new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")

})

test_that("Receivers download - Receivers", {
  skip_on_cran()
  skip_on_appveyor()
  skip_if_no_auth()
  
  unlink("SG-3115BBBK1127.motus")
  expect_message(tagme("SG-3115BBBK1127", new = TRUE, update = TRUE)) %>%
    expect_s3_class("src_sql")
  unlink("SG-3115BBBK1127.motus")
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
  
  unlink("project-176.motus")
})

test_that("tagme with countOnly (tellme) - Receivers", {
  skip("Temp")
  skip_on_cran()
  skip_if_no_auth()
  
  unlink("SG-3115BBBK1127.motus")
  expect_silent(tellme("SG-3115BBBK1127", new = TRUE)) %>%
    expect_is("data.frame")
  unlink("SG-3115BBBK1127.motus")
})

test_that("srvQuery handles time out graciously", {
  
  sample_auth()
  
  # https://stackoverflow.com/questions/100841/artificially-create-a-connection-timeout-error
  expect_message(
    expect_error(srvQuery(API = motus_vars$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT, 
                          params = list(projectID = 176),
                          url = motus_vars$dataServerURL, timeout = 0.01),
                 "The server is not responding"),
    "The server did not respond within 0.01s. Trying again...")
})

test_that("srvAuth handles errors informatively", {
  motusLogout()
  sessionVariable(name = "userLogin", val = "motus.samp")
  sessionVariable(name = "userPassword", val = "motus.samp")
  
  expect_error(srvAuth(), "Authentication failed")
})
