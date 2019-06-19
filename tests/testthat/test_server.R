context("Test Server Access")

test_that("tagme() and tellme() access the server appropriately", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_travis()
  
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  expect_error(expect_message(tagme(projRecv = 10, new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "Internal Server Error")
  
  expect_error(tagme(projRecv = 176, new = TRUE, update = TRUE), NA)
  
  # Clean up
  file.remove("./project-176.motus")
  file.remove("./project-10.motus")
})

test_that("srvQuery handles time out graciously", {
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  # https://stackoverflow.com/questions/100841/artificially-create-a-connection-timeout-error
  expect_message(
    expect_error(srvQuery(API = motus_vars$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT, 
                          params = list(projectID = 176),
                          url = "10.255.255.1", timeout = 1),
                 "The server is not responding"),
    "The server did not respond within 1s. Trying again...")
})

test_that("srvAuth handles errors informatively", {
  sessionVariable(name = "userLogin", val = "motus.samp")
  sessionVariable(name = "userPassword", val = "motus.samp")
  
  expect_error(srvAuth(), "Authentication failed")
})
