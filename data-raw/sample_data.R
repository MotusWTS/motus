# Create a small subset data frame for testing and examples
file.remove("./inst/extdata/project-176.motus")
tags <- tagme(projRecv = 176, new = TRUE, update = TRUE, "./inst/extdata/")
shorebirds <- dplyr::tbl(tags, "alltags") %>%
  dplyr::collect()

usethis::use_data(shorebirds, overwrite = TRUE)

#file.remove("./data-raw/project-176.motus") # Keep this file? 9 megs... not too bad
