context("sql tables")

setup(file.copy(system.file("extdata", "project-176.motus", package = "motus"), "."))
teardown(unlink("project-176.motus"))

test_that("new tables have character ant and port", {
  tags <- DBI::dbConnect(RSQLite::SQLite(), "project-176.motus")
  expect_is(dplyr::tbl(tags, "runs") %>% 
              dplyr::collect() %>% 
              dplyr::pull("ant"), 
            "character")
  
  expect_is(dplyr::tbl(tags, "antDeps") %>% 
              dplyr::collect() %>% 
              dplyr::pull("port"), 
            "character")
  
  # For receivers
  # expect_is(dplyr::tbl(tags, "pulseCounts") %>% 
  #             dplyr::collect() %>% 
  #             dplyr::pull("ant"), 
  #           "character")
  
})


test_that("Missing tables recreated silently", {
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
  
  tags <- tagme(176, new = FALSE, update = FALSE)
  
  t <- DBI::dbListTables(tags$con)
  t <- t[t != "admInfo"] # Don't try removing admInfo table
  
  # t <- c("activity", "antDeps", "batchRuns", "batches",
  #        "clarified", "filters", "gps", "hits", "meta", "projAmbig", "projBatch",
  #        "projs", "recvDeps", "recvs", "runs", "runsFilters", "species", "tagAmbig",
  #        "tagDeps", "tagProps", "tags")
  # 
  
  for(i in t) {
  
    # Remove table
    if(!i %in% c("alltags", "allambigs")) {
      expect_silent(DBI::dbRemoveTable(tags$con, !!i))
      expect_false(DBI::dbExistsTable(tags$con, !!i))
    } else {
      expect_silent(DBI::dbExecute(tags$con, paste0("DROP VIEW ", !!i)))
      expect_false(DBI::dbExistsTable(tags$con, !!i))
    }
    
    # Add tables, no errors
    expect_error(tags <- tagme(176, new = FALSE, update = TRUE), NA)
    expect_true(DBI::dbExistsTable(tags$con, !!i))
  }
})
