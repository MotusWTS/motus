# Create a small subset data frame for testing and examples

sample_auth()

file.remove("./inst/extdata/project-176.motus")
tags <- tagme(projRecv = 176, new = TRUE, update = TRUE, "./inst/extdata/")
shorebirds <- dplyr::tbl(tags, "alltags") %>%
  dplyr::collect()

usethis::use_data(shorebirds, overwrite = TRUE)

#file.remove("./data-raw/project-176.motus") # Keep this file?

if(have_auth()) {
  file.remove("./inst/extdata/SG-3115BBBK0782.motus")
  tagme("SG-3115BBBK0782", new = TRUE, update = TRUE, dir = "./inst/extdata/")
}
