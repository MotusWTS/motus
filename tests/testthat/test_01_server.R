
test_that("srvRecvMetadataForProjects", {

  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  ## srv meta 

  # srvRecvMetadataForProjects
  expect_silent(s <- srvRecvMetadataForProjects(projectIDs = 1)) %>%
    expect_type("list")
  expect_named(s, c("recvDeps", "antDeps", "nodeDeps", "projs"))
  expect_true(all(s$recvDeps$projectID == 1))

  expect_silent(s <- srvRecvMetadataForProjects(projectIDs = NULL)) %>%
    expect_type("list")
  expect_named(s, c("recvDeps", "antDeps", "nodeDeps", "projs"))

})

test_that("srvMetadataForReceivers", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()
  
  # srvMetadataForReceivers
  d <- srvDeviceIDForReceiver("SG-5113BBBK3139")$deviceID
  expect_silent(meta_recv <- srvMetadataForReceivers(deviceIDs = d)) %>%
    expect_type("list")
  expect_named(meta_recv, c("recvDeps", "antDeps", "projs"))
})

test_that("srvMetadataForTags", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvMetadataForTags
  expect_silent(s <- srvMetadataForTags(motusTagIDs = 29876)) %>%
    expect_type("list")
  expect_named(s, c("tags", "tagDeps", "tagProps", "species", "projs"))
  expect_s3_class(s$tagProps, "data.frame")
})

test_that("srvAuth", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()
  
  ## srvAuth 
  expect_silent(srvAuth()) %>%
    expect_type("character")
})


## srv regular

test_that("srvActivityXXX", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvActivityForAll
  expect_silent(s <- srvActivityForAll(batchID = 0, hourBin = 0)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("batchID", "motusDeviceID", "ant", "year", "month", "day", 
                    "hourBin", "numTags", "pulseCount", "numRuns", "numHits",
                    "run2", "run3", "run4", "run5", "run6", "run7plus", 
                    "numGPSfix"))

  # srvActivityForBatches - From Project 4, non-deprecated
  expect_silent(s <- srvActivityForBatches(batchID = 1)) %>%
    expect_s3_class("data.frame")
})

test_that("srvAPIinfo", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()
  
  # srvAPIinfo
  expect_silent(s <- srvAPIinfo()) %>%
    expect_type("list")
  expect_named(s, c("maxRows", "dataVersion", "currentPkgVersion"))
  expect_gt(s$maxRows, 0)
  expect_gt(s$dataVersion, 0)
  expect_type(s$currentPkgVersion, "character")
})

test_that("srvBatchesXXX", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvBatchesForReceiver - From Project 1 (SG-4002BBBK1580)
  expect_silent(s <- srvBatchesForReceiver(deviceID = 217, batchID = 0)) %>%
    expect_s3_class("data.frame")
  expect_named(s, 
               c("motusProjectID", "batchID", "source", "motusDeviceID", "monoBN",
                 "tsStart", "tsEnd", "numHits", "motusJobID", "motusUserID",
                 "ts", "version"))

  # srvBatchesForTagProject
  expect_silent(s <- srvBatchesForTagProject(projectID = 4, batchID = 0)) %>%
    expect_s3_class("data.frame")
  expect_named(s, 
               c("motusProjectID", "batchID", "source", "motusDeviceID", "monoBN",
                 "tsStart", "tsEnd", "numHits", "motusJobID", "motusUserID",
                 "ts", "version"))

  #srvBatchesForReceiverDeprecated
  expect_silent(s <- srvBatchesForReceiverDeprecated(217)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("batchID", "batchFilter"))

  #srvBatchesForTagDeprecated
  expect_silent(s <- srvBatchesForTagProjectDeprecated(1)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("batchID", "batchFilter"))
})


test_that("srvHitsBluBatchesForXXX", {
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvHitsBluBatchesForReceiver - From  1948 (CTT-6CA25D375881)
  expect_silent({
    s <- srvHitsBluBatchesForReceiver(
      deviceID = 1948,
      batchID = 26750740,
      lastBatchID = 26750740 + 10
    )
  }) %>%
    expect_s3_class("data.frame")
  expect_named(s, "batchID")

  # srvHitsBluBatchesForTagProject
  expect_silent({
    s <- srvHitsBluBatchesForTagProject(
      projectID = 622,
      batchID = 26752845,
      lastBatchID = 26752845 + 10
    )
  }) %>%
    expect_s3_class("data.frame")
  expect_named(s, "batchID")


})

test_that("srvDeviceIDForReceiver", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvDeviceIDForReceiver
  expect_silent(s <- srvDeviceIDForReceiver(serno = "CTT-5031194D3168")) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("serno", "deviceID"))
})

test_that("srvGPSXXX", {
  
  skip()

  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvGPSForAll
  expect_silent(s <- srvGPSForAll(gpsID = 1)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("gpsID", "recvDeployID", "ts", "gpsts", "batchID", "lat", 
                    "lon", "alt", "quality", "lat_mean", "lon_mean", 
                    "n_fixes"))

  # srvGPSForReceiver - deviceID = 6115; CTT-5031194D3168
  expect_silent(s <- srvGPSForReceiver(batchID = 1719802)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("gpsID", "recvDeployID", "ts", "gpsts", "batchID", "lat", 
                    "lon", "alt", "quality", "lat_mean", "lon_mean", 
                    "n_fixes"))

  # srvGPSForTagProject - Not sure what's going on
  expect_silent(s <- srvGPSForTagProject(projectID = 1, batchID = 1)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("gpsID", "batchID", "ts", "gpsts", "lat", 
                    "lon", "alt", "quality", "lat_mean", "lon_mean", 
                    "n_fixes"))
})

test_that("srvHitsXXX", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()
  
  # srvHitsForReceiver

  # Get batch to check -  - From Project 1 (SG-4002BBBK1580)
  b <- srvBatchesForReceiver(deviceID = 217, batchID = 0) %>%
    dplyr::filter(numHits > 100) %>%
    dplyr::slice_tail()

  expect_silent(s <- srvHitsForReceiver(batchID = b$batchID)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("hitID", "runID", "batchID", "ts", "sig", "sigSD", "noise",
                    "freq", "freqSD", "slop", "burstSlop", "validated"))
  expect_gt(nrow(s), 1)

  # srvHitsForTagProject
  # Get batch to check -  From Project 1
  # TODO check if we can use real batch?
  #b <- srvBatchesForTagProject(1, batchID = 27072564) %>%
  #  dplyr::slice_tail()
  expect_silent(s <- srvHitsForTagProject(projectID = 1, batchID = 27072564)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("hitID", "runID", "batchID", "ts", "sig", "sigSD", "noise",
                    "freq", "freqSD", "slop", "burstSlop", "validated"))
  expect_gt(nrow(s), 1)

})

test_that("srvHitsBluXXX", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()
  
  # srvHitsBluForReceiver
  # From 1948 (CTT-6CA25D375881)
  expect_silent(s <- srvHitsBluForReceiver(1948, batchID = 26750744)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("hitID", "batchID", "sync", "product", "revision", "payload"))
  expect_gt(nrow(s), 1)

  # srvHitsBluForTagProject
  # From Project 622
  expect_silent(s <- srvHitsBluForTagProject(projectID = 622, batchID = 26752850)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("hitID", "runID", "batchID", "ts", "sig", "sigSD", "noise",
                    "freq", "freqSD", "slop", "burstSlop", "validated"))
  expect_gt(nrow(s), 1)

})

test_that("srvNodes", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvNodes
  expect_silent(s <- srvNodes(projectID = 207, batchID = 1019183)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("projectID", "nodeDataID", "batchID", "ts", "nodeNum", "ant",
                    "sig", "battery", "temperature", "nodets", "firmware", 
                    "solarVolt", "solarCurrent", "solarCurrentCumul", "lat", "lon"))
})

test_that("srvEXTRA", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()

  # srvProjectAmbiguitiesForTagProject - *****************************
  expect_silent(s <- srvProjectAmbiguitiesForTagProject(projectID = 176)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("projectID4", "projectID5", "projectID6",  "projectID1",
                    "ambigProjectID", "projectID2", "projectID3"))

  # srvPulseCountsForReceiver - CTT-5031194D3168
  expect_silent(s <- srvPulseCountsForReceiver(batchID = 40570, ant = 0)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("batchID", "ant", "hourBin", "count"))

  # srvReceiversForProject
  expect_silent(s <- srvReceiversForProject(projectID = 207)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("projectID", "serno", "receiverType", "deviceID", "status",
                    "deployID", "name", "fixtureType", "latitude", "longitude",
                    "isMobile", "tsStart", "tsEnd", "elevation", "StationID"))

  # srvRunsForReceiver - SG-1814BBBK0461
  b <- srvBatchesForReceiver(deviceID = 217, batchID = 0) %>%
    dplyr::filter(numHits > 100) %>%
    dplyr::slice_tail()
  expect_silent(s <- srvRunsForReceiver(batchID = b$batchID)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("runID", "batchIDbegin", "tsBegin", "tsEnd", "done", 
                    "motusTagID", "ant", "nodeNum", "len", "motusFilter"))

  # srvRunsForTagProject
  expect_silent(s <- srvRunsForTagProject(projectID = 4, batchID = 120474)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("runID", "batchIDbegin", "tsBegin", "tsEnd", "done", 
                    "motusTagID", "ant", "len", "nodeNum", "motusFilter"))

  # srvSizeOfUpdateForReceiver
  expect_silent(s <- srvSizeOfUpdateForReceiver(deviceID = 217, batchID = 0)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("numHits", "numBytes", "numRuns", "numBatches", "numGPS"))

  # srvSizeOfUpdateForTagProject - TODO FIX
  # expect_silent(s <- srvSizeOfUpdateForTagProject(projectID = 25, batchID = 0)) %>%
  #   expect_s3_class("data.frame")
  # expect_named(s, c("numHits", "numBytes", "numRuns", "numBatches", "numGPS"))
})
  
test_that("srvTagXXX", {
  
  skip_on_ci()
  skip_if_no_server()
  skip_if_no_auth()
  
  # srvTagMetadataForProjects
  expect_silent(s <- srvTagMetadataForProjects(projectIDs = 25)) %>%
    expect_type("list")
  expect_named(s, c("tags", "tagDeps", "tagProps", "species", "projs"))
  expect_s3_class(s[["tags"]], "data.frame")
  expect_s3_class(s[["tagDeps"]], "data.frame")
  expect_s3_class(s[["tagProps"]], "data.frame")
  expect_s3_class(s[["species"]], "data.frame")
  expect_s3_class(s[["projs"]], "data.frame")
  

  expect_silent(s <- srvTagMetadataForProjects(projectIDs = NULL)) %>%
    expect_type("list")
  expect_named(s, c("tags", "tagDeps", "tagProps", "species", "projs"))
  expect_s3_class(s[["tags"]], "data.frame")
  expect_s3_class(s[["tagDeps"]], "data.frame")
  expect_s3_class(s[["tagProps"]], "data.frame")
  expect_s3_class(s[["species"]], "data.frame")
  expect_s3_class(s[["projs"]], "data.frame")

  # srvTagsForAmbiguities
  expect_silent(s <- srvTagsForAmbiguities(ambigIDs = -56)) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("ambigID", "ambigProjectID", "motusTagID1", "motusTagID2",
                    "motusTagID3", "motusTagID4", "motusTagID5", "motusTagID6"))
  expect_silent(s <- srvTagsForAmbiguities(ambigIDs = c(-56, -106))) %>%
    expect_s3_class("data.frame")
  expect_named(s, c("ambigID", "ambigProjectID", "motusTagID1", "motusTagID2",
                    "motusTagID3", "motusTagID4", "motusTagID5", "motusTagID6"))
})


test_that("srvQuery() and srvTimeout() timeouts", {
  
  sample_auth()
  skip_if_no_server()
  
  expect_silent(srvTimeout()) %>%
    expect_equal(list("motus.timeout" = 120))
  expect_silent(srvTimeout(5))
  expect_equal(options("motus.timeout"), list("motus.timeout" = 5))
  expect_silent(srvTimeout(reset = TRUE))
  expect_equal(options("motus.timeout"), list("motus.timeout" = 120))
  
  
  # https://stackoverflow.com/questions/100841/artificially-create-a-connection-timeout-error
  srvTimeout(0.001)
  expect_message(
    expect_error(srvQuery(API = motus_vars$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT, 
                          params = list(projectID = 176),
                          url = motus_vars$dataServerURL),
                 "The server did not respond within"),
    "The server did not respond within")
  srvTimeout(reset = TRUE)
})

test_that("srvAuth handles errors informatively", {
  skip_if_no_server()
  expect_message(motusLogout())
  sessionVariable(name = "userLogin", val = "motus.samp")
  sessionVariable(name = "userPassword", val = "motus.samp")
  
  expect_error(srvAuth(), "Authentication failed")
})

test_that("metadata()", {
  skip_on_cran()
  skip_if_no_server()
  sample_auth()
  
  tags <- withr::local_db_connection(tagmeSample())
  expect_message(metadata(tags), "Loading complete") %>%
    suppressMessages()
  
  expect_message(metadata(tags, projectIDs = 45), "Loading complete") %>%
    suppressMessages()
})

test_that("srvAuth errors/warns/passes on package version", {
  sample_auth()
  skip_if_no_server()
  expect_silent(srvAuth())
  expect_true(!is.null(motus_vars$currentPkgVersion))
    
  v <- package_version(motus_vars$currentPkgVersion)
  v <- c(v, v, v)
  v[[c(1,1)]] <- as.numeric(v[[c(1,1)]]) - 1
  v[[c(3,1)]] <- as.numeric(v[[c(3,1)]]) + 1
  v <- as.character(v)
  
  mock <- mockery::mock(v[1], v[2], v[3], cycle = TRUE)
  mockery::stub(srvAuth, "pkg_version", mock)
  
  expect_warning(srvAuth())
  expect_silent(srvAuth())
  expect_silent(srvAuth())
  expect_length(mock, 3)
})
