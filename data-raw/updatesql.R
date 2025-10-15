# IMPORTANT! RUN THIS ENTIRE FILE AFTER MAKING ANY CHANGES and then re-build and re-load the package

sql_versions <- dplyr::tibble()

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2021-02-26",
        descr = "Add stationName and stationID fields to recvDeps table",
        sql = paste0("ALTER TABLE recvDeps ADD COLUMN stationName TEXT;",
                     "ALTER TABLE recvDeps ADD COLUMN stationID INTEGER;")))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2021-02-26",
        descr = "Add numGPSfix field to activity and activityAll tables",
        sql = paste0("ALTER TABLE activity ADD COLUMN numGPSfix INTEGER;",
                     "ALTER TABLE activityAll ADD COLUMN numGPSfix INTEGER;")))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2021-02-26",
        descr = "Add activityAll and gpsAll tables",
        sql = paste0(makeTable(name = "activityAll"),
                     makeTable(name = "gpsAll"))))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2021-02-25",
        descr = "Drop IS NOT NULL constraint on nodeDeps ts",
        sql = paste0("CREATE TABLE IF NOT EXISTS nodeDeps2 (
                      deployID INTEGER NOT NULL,
                      nodeDeployID BIGINT PRIMARY KEY NOT NULL, 
                      latitude  FLOAT, 
                      longitude FLOAT, 
                      tsStart FLOAT NOT NULL, 
                      tsEnd FLOAT);
                      INSERT INTO nodeDeps2 SELECT * FROM nodeDeps;
                      DROP TABLE nodeDeps;
                      ALTER TABLE nodeDeps2 RENAME TO nodeDeps;")))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2020-08-07",
        descr = "Rename nodeDataId to nodeDataID in nodeData",
        sql = paste0("ALTER TABLE nodeData RENAME TO nodeData2;",
                     makeTable(name = "nodeData"),
                     "INSERT INTO nodeData SELECT * FROM nodeData2;",
                     "DROP TABLE nodeData2;")))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2020-08-06", 
        descr = "Add new CTT V2 fields to 'gps', 'nodeData' and 'hits' tables",
        sql = paste0("ALTER TABLE gps ADD COLUMN lat_mean FLOAT;",
                     "ALTER TABLE gps ADD COLUMN lon_mean FLOAT;",
                     "ALTER TABLE gps ADD COLUMN n_fixes INTEGER;",
                     "ALTER TABLE nodeData ADD COLUMN nodets FLOAT;",
                     "ALTER TABLE nodeData ADD COLUMN firmware VARCHAR(20);",
                     "ALTER TABLE nodeData ADD COLUMN solarVolt FLOAT;",
                     "ALTER TABLE nodeData ADD COLUMN solarCurrent FLOAT;",
                     "ALTER TABLE nodeData ADD COLUMN solarCurrentCumul FLOAT;",
                     "ALTER TABLE nodeData ADD COLUMN lat FLOAT;",
                     "ALTER TABLE nodeData ADD COLUMN lon FLOAT;",
                     "ALTER TABLE hits ADD COLUMN validated TINYINT;")))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2020-05-22",
        descr = "Add 'antFreq' 'antDeps' table",
        sql = "ALTER TABLE antDeps ADD COLUMN antFreq REAL;"))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2020-04-24",
        descr = "Add 'test' metadata to 'tagDeps' table",
        sql = paste0("ALTER TABLE tagDeps ADD COLUMN test INTEGER;",
                     # Dropped views are recreated in later steps
                     "DROP VIEW IF EXISTS alltags;",
                     "DROP VIEW IF EXISTS alltagsGPS;",
                     "DROP VIEW IF EXISTS allruns;",
                     "DROP VIEW IF EXISTS allrunsGPS;")))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2020-04-23",
        descr = "Add 'sex' and 'age' metadata to 'tagDeps' table",
        sql = paste0("ALTER TABLE tagDeps ADD COLUMN sex TEXT;",
                     "ALTER TABLE tagDeps ADD COLUMN age TEXT;")))

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2019-11-20",
        descr = "Drop IS NOT NULL constraint on allambigs",
        sql = paste0("DROP VIEW IF EXISTS allambigs;",   # Remove Views so we can delete the table
                     "DROP VIEW IF EXISTS alltagsGPS;", 
                     "DROP VIEW IF EXISTS alltags;",
                     "DROP VIEW IF EXISTS allruns;",
                     "DROP VIEW IF EXISTS allrunsGPS;",
                     "ALTER TABLE tagAmbig RENAME TO tagAmbig2;",
                     makeTable(name = "tagAmbig"), 
                     "INSERT INTO tagAmbig SELECT * FROM tagAmbig2;
                      DROP TABLE tagAmbig2;"))
)

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2019-11-15",
        descr = "Move GPS data from alltags view to alltagsGPS view",
        # Remove Views, will be recreated in next step
        sql = paste0("DROP VIEW IF EXISTS allambigs;",
                     "DROP VIEW IF EXISTS alltagsGPS;", 
                     "DROP VIEW IF EXISTS alltags;",
                     "DROP VIEW IF EXISTS allruns;",
                     "DROP VIEW IF EXISTS allrunsGPS;"))
)

sql_versions <- dplyr::mutate(sql_versions, 
                              date = lubridate::as_datetime(as.character(date), tz = "UTC"),
                              sql = as.character(sql))






