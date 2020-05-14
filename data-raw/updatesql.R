sql_versions <- dplyr::tibble()

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2020-04-22",
        descr = "Rename nodeDataId to nodeDataID in nodeData",
        sql = paste0("ALTER TABLE nodeData RENAME TO nodeData2;",
                     makeTables(type = "nodeData"),
                     "INSERT INTO nodeData SELECT * FROM nodeData2;",
                     "DROP TABLE nodeData2;"))
)

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2019-11-20",
        descr = "Drop IS NOT NULL constraint on allambigs",
        sql = paste0("DROP VIEW IF EXISTS allambigs;",   # Remove Views so we can delete the table
                     "DROP VIEW IF EXISTS alltagsGPS;", 
                     "DROP VIEW IF EXISTS alltags;",
                     makeTables(type = "tagAmbig", name = "tagAmbig2"), 
                     "INSERT INTO tagAmbig2 SELECT * FROM tagAmbig;
                      DROP TABLE tagAmbig;
                      ALTER TABLE tagAmbig2 RENAME TO tagAmbig;"))
)

sql_versions <- rbind(
  sql_versions,
  cbind(date = "2019-11-15",
        descr = "Move GPS data from alltags view to alltagsGPS view",
        # Remove Views, will be recreated in next step
        sql = paste0("DROP VIEW IF EXISTS allambigs;",
                     "DROP VIEW IF EXISTS alltagsGPS;", 
                     "DROP VIEW IF EXISTS alltags;"))
)

sql_versions <- dplyr::mutate(sql_versions, 
                              date = lubridate::as_datetime(as.character(date), tz = "UTC"),
                              sql = as.character(sql))

usethis::use_data(sql_versions, internal = TRUE, overwrite = TRUE)







