context("sql tables")

setup({
  unlink(list.files(pattern = "*.motus"))
  unlink(list.files(pattern = "project-176_custom_views"))
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
})

teardown({
  unlink(list.files(pattern = "*.motus"))
})

# Create DB, includes new tables

test_that("Create DB, includes any new tables", {
  temp <- dbplyr::src_dbi(DBI::dbConnect(RSQLite::SQLite(), "temp.motus")) %>%
    expect_silent()
  expect_length(DBI::dbListTables(temp$con), 0)
  expect_silent(ensureDBTables(temp, 176, quiet = TRUE))
  
  t <- DBI::dbListTables(temp$con)
  
  # Expect activityAll and gpsAll
  expect_true(all(c("activityAll", "gpsAll") %in% t)) 
  
  # Expect Deprecated
  expect_true("deprecated" %in% t)
  
  unlink("temp.motus")
})

# Create DB, includes any new fields -----------------------------------------
test_that("Create DB, includes any new fields", {
  expect_silent(temp <- dbplyr::src_dbi(DBI::dbConnect(RSQLite::SQLite(), 
                                                       "temp.motus")))
  expect_length(DBI::dbListTables(temp$con), 0)
  
  expect_message(ensureDBTables(temp, 176, quiet = FALSE))
  expect_silent(ensureDBTables(temp, 176, quiet = TRUE))
  expect_silent(temp <- dbplyr::src_dbi(DBI::dbConnect(RSQLite::SQLite(), 
                                                       "temp.motus")))
  expect_length(t <- DBI::dbListTables(temp$con), 32)
  
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
  
  # Expect new columns in activity/activityAll
  expect_true(all(c("numGPSfix") %in% DBI::dbListFields(temp$con, "activity")))
  expect_true(all(c("numGPSfix") %in% DBI::dbListFields(temp$con, "activityAll")))
  
  # Expect new columns in recvDeps
  expect_true(all(c("stationName", "stationID") %in% 
                    DBI::dbListFields(temp$con, "recvDeps")))

  unlink("temp.motus")
})


# views created correctly -------------------------------------------------
test_that("Views created correctly", {
  unlink("project-176-backup.motus")
  file.copy("project-176.motus", "project-176-backup.motus")
  tags <- tagme(176, update = FALSE, new = FALSE)
  
  views <- c("allambigs", "alltags", "alltagsGPS", "allruns", "allrunsGPS")
  
  # Remove existing views
  for(v in views) DBI::dbExecute(tags$con, glue::glue("DROP VIEW IF EXISTS {v}"))
  
  # Add views
  tags <- ensureDBTables(tags, projRecv = 176)
  
  # Check that views present
  expect_true(all(views %in% DBI::dbListTables(tags$con)))
  
  # Check that data in views correct
  allruns <- dplyr::tbl(tags$con, "allruns")
  allrunsGPS <- dplyr::tbl(tags$con, "allrunsGPS")
  alltags <- dplyr::tbl(tags$con, "alltags")
  alltagsGPS <- dplyr::tbl(tags$con, "alltagsGPS")
  
  # More fields in GPS views
  expect_gt(ncol(allrunsGPS), ncol(allruns))
  expect_gt(ncol(alltagsGPS), ncol(alltags))
  
  # No hits in runs views
  expect_false("hitID" %in% dplyr::tbl_vars(allruns))
  expect_false("hitID" %in% dplyr::tbl_vars(allrunsGPS))
  
  # Hits in tags views
  expect_true("hitID" %in% dplyr::tbl_vars(alltags))
  expect_true("hitID" %in% dplyr::tbl_vars(alltagsGPS))
  
  # More rows in tags than runs view
  expect_gt(nrow(at <- alltags %>% dplyr::collect()),
            nrow(ar <- allruns %>% dplyr::collect()))
  expect_gt(nrow(atGPS <- alltagsGPS %>% dplyr::collect()),
            nrow(arGPS <- allrunsGPS %>% dplyr::collect()))
  
  # Expect same batches and runIDs
  expect_equal(unique(at$batchID), unique(ar$batchID))
  expect_equal(unique(at$runID), unique(ar$runID))
  expect_equal(unique(atGPS$batchID), unique(arGPS$batchID))
  expect_equal(unique(atGPS$runID), unique(arGPS$runID))
  
  unlink("project-176.motus")
  file.rename("project-176-backup.motus", "project-176.motus")
})


# new tables have character ant and port ----------------------------------
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


# missing tables recreated ------------------------------------------------
test_that("Missing tables recreated silently", {
  sample_auth()
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  tags <- tagme(176, new = FALSE, update = FALSE)
  
  t <- DBI::dbListTables(tags$con)
  t <- t[t != "admInfo"] # Don't try removing admInfo table
  
  for(i in t) {
    # Remove table/view
    if(!i %in% c("alltags", "allambigs", "alltagsGPS", "allruns", "allrunsGPS")) {
      expect_silent(DBI::dbRemoveTable(tags$con, !!i))
      expect_false(DBI::dbExistsTable(tags$con, !!i))
    } else {
      expect_silent(DBI::dbExecute(tags$con, paste0("DROP VIEW ", !!i)))
      expect_false(DBI::dbExistsTable(tags$con, !!i))
    }
  }
  
  # Add tables, no errors
  expect_message(tags <- tagme(176, new = FALSE, update = TRUE))
  
  for(i in t) expect_true(DBI::dbExistsTable(tags$con, !!i))
  
  unlink("project-176.motus")
})


# check for custom views before updating ----------------------------------
test_that("check for custom views before update", {
  # Get clean database
  sample_auth()
  unlink("project-176.motus")
  unlink(list.files(pattern = "project-176_custom_views"))
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  
  # Add custom view
  tags <- DBI::dbConnect(RSQLite::SQLite(), "project-176.motus")
  DBI::dbExecute(
    tags, 
    "CREATE VIEW alltags_fast AS SELECT hitID, runID, ts FROM alltags WHERE sig = 52;")
  DBI::dbExecute(tags, "UPDATE admInfo SET db_version = '2019-01-01 00:00:00'")
  DBI::dbDisconnect(tags)
  tags <- tagme(176, update = FALSE)
  
  # Test for handling of custom view
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

