
test_that("ensureDBTables gets correct receivers", {
  tags <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_silent(ensureDBTables(tags, projRecv = "CTT-18BC3777F716", deviceID = 1860))
  expect_s3_class(m <- dplyr::tbl(tags, "meta") %>% dplyr::collect(), "data.frame")
  expect_equal(m$val[m$key == "recvType"], "CTT")
  expect_equal(m$val[m$key == "recvModel"], "V2")
  
  tags <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_silent(ensureDBTables(tags, projRecv = "CTT-867762040710391", deviceID = 1860))
  expect_s3_class(m <- dplyr::tbl(tags, "meta") %>% dplyr::collect(), "data.frame")
  expect_equal(m$val[m$key == "recvType"], "CTT")
  expect_equal(m$val[m$key == "recvModel"], "V1")
  
  
  tags <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_silent(ensureDBTables(tags, projRecv = "SG-BC3FRPI35A70", deviceID = 1261))
  expect_s3_class(m <- dplyr::tbl(tags, "meta") %>% dplyr::collect(), "data.frame")
  expect_equal(m$val[m$key == "recvType"], "SENSORGNOME")
  expect_equal(m$val[m$key == "recvModel"], "RPI3")
  
  #srvDeviceIDForReceiver("SEI_A_210701002")$deviceID
  tags <- withr::local_db_connection(DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_silent(ensureDBTables(tags, projRecv = "SEI_A_210701002", deviceID = 2422))
  expect_s3_class(m <- dplyr::tbl(tags, "meta") %>% dplyr::collect(), "data.frame")
  expect_equal(m$val[m$key == "recvType"], "SigmaEight")
  expect_equal(m$val[m$key == "recvModel"], "Ares")
})
