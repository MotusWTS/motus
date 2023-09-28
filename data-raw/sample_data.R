# Create a small subset data frame for testing and examples

set_testing(set = FALSE)
sample_auth()
unlink("./inst/extdata/project-176.motus")
tags <- tagme(projRecv = 176, new = TRUE, update = TRUE, dir = "./inst/extdata/")

#file.remove("./data-raw/project-176.motus") # Keep this file?

if(have_auth()) {
  local_auth()
  
  # Update receiver
  set_testing()
  orig <- options(motus.test.max = 60)
  unlink("./inst/extdata/SG-3115BBBK0782.motus")
  t <- tagme("SG-3115BBBK0782", new = TRUE, update = TRUE, dir = "./inst/extdata/")
  DBI::dbDisconnect(t)
  options(orig)
  
  # Update project 4
  unlink("./inst/extdata/project-4.motus")
  tagme(4, new = TRUE, update = TRUE, dir = "./inst/extdata/")
  set_testing(set = FALSE)
  
  # Create small sample for GPS tests
  file.copy("./inst/extdata/project-4.motus", 
            "./inst/extdata/gps_sample.motus", overwrite = TRUE)
}
