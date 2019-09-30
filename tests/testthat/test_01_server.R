context("Test Server Access")


  unlink("project-10.motus")
})

test_that("tagme() errors appropriately", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_travis()
  
  if(file.exists("project-10.motus")) unlink("project-10.motus")
  
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  expect_error(expect_message(tagme(projRecv = 10, new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "You do not have permission")
  if(file.exists("project-10.motus")) unlink("project-10.motus")
})

test_that("tagme() downloads data", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_travis()
  
  if(file.exists("project-176.motus")) unlink("project-176.motus")
  
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  expect_message(tags <- tagme(projRecv = 176, new = TRUE, update = TRUE)) %>%
    expect_is("src_SQLiteConnection")
  
  # Table exists
  expect_silent(a <- dplyr::tbl(tags, "activity") %>% dplyr::collect())
  
  # No all missing values
  expect_false(any(sapply(a, function(x) all(is.na(x)))))
  
  # All numeric/integer (except ant)
  expect_is(a$ant, "character")
  for(i in names(a)[names(a) != "ant"]) {
    expect_is(a[, !!i][[1]], c("integer", "numeric"))
  }
})

test_that("tagme with countOnly (tellme)", {
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  expect_silent(tagme(projRecv = 176, new = FALSE, 
                      update = TRUE, countOnly = TRUE)) %>%
    expect_is("data.frame")
  
  expect_silent(tellme(projRecv = 176, new = FALSE)) %>%
    expect_is("data.frame")
  if(file.exists("project-10.motus")) unlink("project-10.motus")
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
