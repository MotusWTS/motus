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
  
  file.remove("./inst/extdata/project-4.motus")
  tagme(4, new = TRUE, update = TRUE, dir = "./inst/extdata/")
  
  # Create small sample for GPS tests
  file.copy("./inst/extdata/project-4.motus", "./inst/extdata/gps_sample.motus", overwrite = TRUE)
  tags <- DBI::dbConnect(RSQLite::SQLite(), "./inst/extdata/gps_sample.motus")
  
  # Find good data section
  xlim <- c(18170, 18171)
  gps <- dplyr::tbl(tags, "gps") %>%
    dplyr::mutate(ts2 = as.integer(ts/(24*3600))) %>%
    dplyr::filter(ts2 >= !!xlim[1], ts2 <= !!xlim[2]) %>%
    dplyr::collect()
  hits <- dplyr::tbl(tags, "hits") %>%
    dplyr::filter(batchID %in% !!gps$batchID) %>%
    dplyr::mutate(ts2 = as.integer(ts/(24*3600))) %>%
    dplyr::filter(ts2 >= !!xlim[1], ts2 <= !!xlim[2]) %>%
    dplyr::collect()

  library(ggplot2)
  ggplot(data = gps, aes(x = ts2)) +
    geom_histogram(fill = "red", alpha = 0.3, colour = "black", binwidth = 1) +
    geom_histogram(data = hits, fill = "blue", alpha = 0.3, colour = "black", binwidth = 1) +
    coord_cartesian(ylim = c(0, 20))

  xlim * (24*3600)
  ## Use ts limits of 1569888000 1569974400
                                                                        
  DBI::dbExecute(tags, "DELETE FROM hits WHERE ts < 1569888000 OR ts > 1569974400")
  DBI::dbExecute(tags, "DELETE FROM gps WHERE ts < 1569888000 OR ts > 1569974400")
  DBI::dbExecute(tags, "DELETE FROM batches WHERE ts < 1569888000 OR ts > 1569974400")
  DBI::dbExecute(tags, "DELETE FROM runs WHERE tsBegin < 1569888000 OR tsEnd > 1569974400")
  DBI::dbRemoveTable(tags, "activity")
  DBI::dbExecute(tags, "VACUUM")
  DBI::dbDisconnect(tags)  
}
