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
