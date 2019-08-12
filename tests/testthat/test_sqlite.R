context("sql tables")

teardown(unlink("project-176.motus"))

test_that("Missing tables recreated silently", {
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  tags <- tagme(176, new = FALSE, update = FALSE)
  
  t <- DBI::dbListTables(tags$con)
  
  #c("activity", "admInfo", "allambits", "antDeps", "batchRuns", "batches",
  #       "clarified", "filters", "gps", "hits", "meta", "projAmbig", "projBatch",
  #       "projs", "recvDeps", "recvs", "runs", "runsFilters", "species", "tagAmbig",
  #       "tagDeps", "tagProps", "tags")
  #v <- "alltags"
  
  for(i in t) {
    
    # Remove table
    if(!i %in% c("alltags", "allambigs")) {
      expect_silent(DBI::dbRemoveTable(tags$con, !!i))
    } else {
      expect_silent(DBI::dbExecute(tags$con, "DROP VIEW alltags"))
    }
    
    # Add table silently (unless admInfo)
    if(i == "admInfo") {
      expect_message(tags <- tagme(176, new = FALSE, update = FALSE))
    } else {
      expect_silent(tags <- tagme(176, new = FALSE, update = FALSE))
    }
    
    expect_true(DBI::dbExistsTable(tags$con, !!i))
    
    # USUALLY expect present but empty (except admInfo and views)
    if(!i %in% c("admInfo", "alltags", "allambigs", "meta")) {
      expect_equal(nrow(dplyr::collect(dplyr::tbl(tags$con, !!i))), 0)
    } 
  }
})