test_that("Create DB, includes any new tables", {
  withr::local_file("temp.motus")
  temp <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), "temp.motus")) %>%
    expect_silent()
  expect_length(DBI::dbListTables(temp), 0)
  expect_silent(ensureDBTables(temp, 176, quiet = TRUE))
  
  t <- DBI::dbListTables(temp)
  
  # Expect activityAll and gpsAll
  expect_true(all(c("activityAll", "gpsAll") %in% t)) 
  
  # Expect Deprecated
  expect_true("deprecated" %in% t)
})

# Create DB, includes any new fields -----------------------------------------
test_that("Create DB, includes any new fields", {
  withr::local_file("temp.motus")
  temp <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), "temp.motus")) %>%
    expect_silent()
  expect_length(DBI::dbListTables(temp), 0)
  
  DBI_ExecuteAll(
    temp,
    c("CREATE TABLE admInfo (db_version TEXT, data_version TEXT);",
      "INSERT INTO admInfo (db_version, data_version) VALUES('2000-01-01', 0);"))
  expect_message(ensureDBTables(temp, 176, quiet = FALSE)) %>%
    suppressMessages()
  
  expect_silent(ensureDBTables(temp, 176, quiet = TRUE))
  expect_length(t <- DBI::dbListTables(temp), 32)
  
  # Expect columns in the tables
  for(i in t) expect_gte(ncol(dplyr::tbl(temp, !!i)), 2)

  # Expect no data in the tables
  for(i in t[!t %in% c("admInfo", "meta")]){
    expect_equal(nrow(DBI::dbGetQuery(temp, paste0("SELECT * FROM ", !!i))),
                 0)
  }
  expect_equal(nrow(DBI_Query(temp, "SELECT * FROM admInfo")), 1)
  expect_equal(nrow(DBI_Query(temp, "SELECT * FROM meta")), 2)
  
  # Expect new columns age/sex in tagDeps
  expect_true(all(c("age", "sex") %in% DBI::dbListFields(temp, "tagDeps")))
  
  # Expect new columns in gps
  expect_true(all(c("lat_mean", "lon_mean", "n_fixes") %in% 
                    DBI::dbListFields(temp, "gps")))
  
  # Expect new columns in nodeData
  expect_true(all(c("nodets", "firmware", "solarVolt", "solarCurrent", 
                    "solarCurrentCumul", "lat", "lon") %in% 
                    DBI::dbListFields(temp, "nodeData")))
  
  # Expect no NOT NULL in nodeDeps tsEnd
  expect_equal(DBI_Query(temp, "PRAGMA table_info(nodeDeps)") %>%
                 dplyr::filter(name == "tsEnd") %>%
                 dplyr::pull(notnull), 
               0)
  
  # Expect new columns in hits
  expect_true(all(c("validated") %in% DBI::dbListFields(temp, "hits")))
  
  # Expect new columns in activity/activityAll
  expect_true(all(c("numGPSfix") %in% DBI::dbListFields(temp, "activity")))
  expect_true(all(c("numGPSfix") %in% DBI::dbListFields(temp, "activityAll")))
  
  # Expect new columns in recvDeps
  expect_true(all(c("stationName", "stationID") %in% 
                    DBI::dbListFields(temp, "recvDeps")))
})


# views created correctly -------------------------------------------------
test_that("Views created correctly", {
  withr::local_file("project-176.motus")
  tags <- withr::local_db_connection(tagmeSample())
  
  views <- c("allambigs", "alltags", "alltagsGPS", "allruns", "allrunsGPS")
  
  # Remove existing views
  for(v in views) DBI_Execute(tags, "DROP VIEW IF EXISTS {v}")
  
  # Add views
  tags <- ensureDBTables(tags, projRecv = 176)
  
  # Check that views present
  expect_true(all(views %in% DBI::dbListTables(tags)))
  
  # Check that data in views correct
  allruns <- dplyr::tbl(tags, "allruns")
  allrunsGPS <- dplyr::tbl(tags, "allrunsGPS")
  alltags <- dplyr::tbl(tags, "alltags")
  alltagsGPS <- dplyr::tbl(tags, "alltagsGPS")
  
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
})


# new tables have character ant and port ----------------------------------
test_that("new tables have character ant and port", {
  tags <- withr::local_db_connection(tagmeSample())
  
  expect_type(dplyr::tbl(tags, "runs") %>% 
              dplyr::collect() %>% 
              dplyr::pull("ant"), 
            "character")
  
  expect_type(dplyr::tbl(tags, "antDeps") %>% 
              dplyr::collect() %>% 
              dplyr::pull("port"), 
            "character")
  
  # For receivers
  skip_if_no_auth()
  f <- "SG-3115BBBK0782.motus"
  skip_if_no_file(f)
  withr::local_file(f)
  tags <- withr::local_db_connection(tagmeSample(f))
  expect_type(dplyr::tbl(tags, "pulseCounts") %>% 
              dplyr::collect() %>% 
              dplyr::pull("ant"), 
            "character")
})


# missing tables recreated ------------------------------------------------
test_that("Missing tables recreated silently", {
  sample_auth()
  withr::local_file("project-176.motus")
  skip_if_no_file("project-176.motus", copy = TRUE)
  tags <- withr::local_db_connection(tagme(176, new = FALSE, update = FALSE))
  
  t <- DBI::dbListTables(tags)
  t <- t[t != "admInfo"] # Don't try removing admInfo table
  
  for(i in t) {
    # Remove table/view
    if(!i %in% c("alltags", "allambigs", "alltagsGPS", "allruns", "allrunsGPS")) {
      expect_silent(DBI::dbRemoveTable(tags, !!i))
      expect_false(DBI::dbExistsTable(tags, !!i))
    } else {
      expect_silent(DBI::dbExecute(tags, paste0("DROP VIEW ", !!i)))
      expect_false(DBI::dbExistsTable(tags, !!i))
    }
  }
  
  # Add tables, no errors
  expect_message(tags <- withr::local_db_connection(
    tagme(176, new = FALSE, update = TRUE))) %>%
    suppressMessages()
  
  for(i in t) expect_true(DBI::dbExistsTable(tags, !!i))
})


# check for custom views before updating ----------------------------------
test_that("check for custom views before update", {
  sample_auth()
  withr::local_file("project-176.motus")
  withr::local_file(paste0("project-176_custom_views_", Sys.Date(), ".log"))
  skip_if_no_file("project-176.motus", copy = TRUE)
  tags <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), "project-176.motus"))
  
  # Add custom view
  DBI_Execute(
    tags, 
    "CREATE VIEW alltags_fast AS SELECT hitID, runID, ts FROM alltags WHERE sig = 52;")
  DBI_Execute(tags, "UPDATE admInfo SET db_version = '2019-01-01 00:00:00'")
  
  # Test for handling of custom view
  expect_error(checkViews(src = tags, update_sql = sql_versions$sql, response = 2),
               "Cannot update local database if conflicting custom views")
  expect_true("alltags_fast" %in% DBI::dbListTables(tags))
  expect_message(checkViews(src = tags, update_sql = sql_versions$sql, response = 1),
                 "Deleting custom views: alltags_fast")
  expect_true(file.exists(paste0("project-176_custom_views_", Sys.Date(), ".log")))
  
  expect_true(any(stringr::str_detect(readLines(paste0("project-176_custom_views_", 
                                                       Sys.Date(), ".log")),
                                      "CREATE VIEW alltags_fast")))
  expect_false("alltags_fast" %in% DBI::dbListTables(tags))
   
  expect_message(withr::local_db_connection(tagme(176, update = TRUE)), 
                 "updateMotusDb started") %>%
    suppressMessages()
})

