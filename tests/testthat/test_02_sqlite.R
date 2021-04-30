context("sql tables")

setup({
  unlink("project-176.motus")
  unlink("temp.motus")
  unlink(list.files(pattern = "project-176_custom_views"))
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
})

teardown({
  unlink("project-176.motus")
  unlink("temp.motus")
})

test_that("ensureDBTables() creates database", {
  expect_silent(temp <- dbplyr::src_dbi(DBI::dbConnect(RSQLite::SQLite(), "temp.motus")))
  expect_length(DBI::dbListTables(temp$con), 0)
  
  expect_message(ensureDBTables(temp, 176, quiet = FALSE))
  expect_silent(ensureDBTables(temp, 176, quiet = TRUE))
  expect_silent(temp <- dbplyr::src_dbi(DBI::dbConnect(RSQLite::SQLite(), "temp.motus")))
  expect_length(t <- DBI::dbListTables(temp$con), 27)
  
  # Expect columns in the tables
  for(i in t) expect_gte(ncol(dplyr::tbl(temp$con, !!i)), 2)

  # Expect no data in the tables
  for(i in t[!t %in% c("admInfo", "meta")]){
    expect_equal(nrow(DBI::dbGetQuery(temp$con, paste0("SELECT * FROM ", !!i))),
                 0)
  }
  expect_equal(nrow(DBI::dbGetQuery(temp$con, "SELECT * FROM admInfo")), 1)
  expect_equal(nrow(DBI::dbGetQuery(temp$con, "SELECT * FROM meta")), 2)
  
  # Expect new columns age/sex in tagDeps
  expect_true(all(c("age", "sex") %in% DBI::dbListFields(temp$con, "tagDeps")))
  
  # Expect new columns in gps
  expect_true(all(c("lat_mean", "lon_mean", "n_fixes") %in% 
                    DBI::dbListFields(temp$con, "gps")))
  
  # Expect new columns in nodeData
  expect_true(all(c("nodets", "firmware", "solarVolt", "solarCurrent", 
                    "solarCurrentCumul", "lat", "lon") %in% 
                    DBI::dbListFields(temp$con, "nodeData")))
  
  # Expect no NOT NULL in nodeDeps tsEnd
  expect_equal(DBI::dbGetQuery(temp$con, "PRAGMA table_info(nodeDeps)") %>%
                 dplyr::filter(name == "tsEnd") %>%
                 dplyr::pull(notnull), 
               0)
  
  # Expect new columns in hits
  expect_true(all(c("validated") %in% DBI::dbListFields(temp$con, "hits")))

  unlink("temp.motus")

})

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
  skip_if_no_auth()
  f <- system.file("extdata", "SG-3115BBBK0782.motus", package = "motus")
  skip_if_no_file(f)
  tags <- DBI::dbConnect(RSQLite::SQLite(), f)
  expect_is(dplyr::tbl(tags, "pulseCounts") %>% 
              dplyr::collect() %>% 
              dplyr::pull("ant"), 
            "character")
  
})

test_that("Missing tables recreated silently", {
  sample_auth()
  tags <- tagme(176, new = FALSE, update = FALSE)
  
  t <- DBI::dbListTables(tags$con)
  t <- t[t != "admInfo"] # Don't try removing admInfo table
  
  # t <- c("activity", "antDeps", "batchRuns", "batches",
  #        "clarified", "filters", "gps", "hits", "meta", "projAmbig", "projBatch",
  #        "projs", "recvDeps", "recvs", "runs", "runsFilters", "species", "tagAmbig",
  #        "tagDeps", "tagProps", "tags")
  # 
  
  for(i in t) {
    # Remove table/view
    if(!i %in% c("alltags", "allambigs", "alltagsGPS")) {
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


test_that("check for custom views before update", {
  sample_auth()
  tags <- DBI::dbConnect(RSQLite::SQLite(), "project-176.motus")
  DBI::dbExecute(
    tags, 
    "CREATE VIEW alltags_fast AS SELECT hitID, runID, ts FROM alltags WHERE sig = 52;")
  DBI::dbExecute(tags, "UPDATE admInfo SET db_version = '2019-01-01 00:00:00'")
  DBI::dbDisconnect(tags)
  
  tags <- tagme(176, update = FALSE)
  expect_error(checkViews(src = tags, update_sql = sql_versions$sql, response = 2),
               "Cannot update local database if conflicting custom views")
  expect_true("alltags_fast" %in% DBI::dbListTables(tags$con))
  expect_message(checkViews(src = tags, update_sql = sql_versions$sql, response = 1),
                 "Deleting custom views: alltags_fast")
  expect_true(file.exists(paste0("project-176_custom_views_", Sys.Date(), ".log")))
  
  expect_true(any(stringr::str_detect(readLines(paste0("project-176_custom_views_", 
                                                       Sys.Date(), ".log")),
                                      "CREATE VIEW alltags_fast")))
  expect_false("alltags_fast" %in% DBI::dbListTables(tags$con))
   
  expect_message(tagme(176, update = TRUE), "updateMotusDb started")
  
  unlink(paste0("project-176_custom_views_", Sys.Date(), ".log"))
})

