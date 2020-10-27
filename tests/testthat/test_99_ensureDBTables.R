
test_that("ensureDBTables gets correct receivers", {
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_message(ensureDBTables(tags, projRecv = "CTT-18BC3777F716", deviceID = 1860), 
                 "updateMotusDb started")
  expect_is(m <- dplyr::tbl(tags, "meta") %>% dplyr::collect(), "data.frame")
  expect_equal(m$val[m$key == "recvType"], "CTT")
  expect_equal(m$val[m$key == "recvModel"], "V2")
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_message(ensureDBTables(tags, projRecv = "CTT-867762040710391", deviceID = 1860), 
                 "updateMotusDb started")
  expect_is(m <- dplyr::tbl(tags, "meta") %>% dplyr::collect(), "data.frame")
  expect_equal(m$val[m$key == "recvType"], "CTT")
  expect_equal(m$val[m$key == "recvModel"], "V1")
  
  
  tags <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), ":memory:"))
  expect_message(ensureDBTables(tags, projRecv = "SG-BC3FRPI35A70", deviceID = 1261), 
                 "updateMotusDb started")
  expect_is(m <- dplyr::tbl(tags, "meta") %>% dplyr::collect(), "data.frame")
  expect_equal(m$val[m$key == "recvType"], "SENSORGNOME")
  expect_equal(m$val[m$key == "recvModel"], "RPI3")
  
})