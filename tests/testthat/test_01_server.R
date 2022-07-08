o <- options(connectionObserver = NULL)
# srvXXX tests ---------------------------------------
test_that("srvXXX work as expected", {
  
  skip_if_no_auth()
  
  #srvAuth
  expect_silent(srvAuth()) %>%
    expect_type("character")
  
  # srvActivityForAll
  expect_silent(s <- srvActivityForAll(batchID = 0, hourBin = 0)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvActivityForBatches - From Project 4, non-deprecated
  expect_silent(s <- srvActivityForBatches(batchID = 118721)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvAPIinfo
  expect_silent(s <- srvAPIinfo()) %>%
    expect_type("list")
  expect_named(s, c("maxRows", "dataVersion", "currentPkgVersion"))
  expect_gt(s$maxRows, 0)
  expect_gt(s$dataVersion, 0)
  
  # srvBatchesForReceiver - From Project 1 (SG-4002BBBK1580)
  expect_silent(s <- srvBatchesForReceiver(deviceID = 217, batchID = 0)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvBatchesForTagProject
  # expect_silent(s <- srvBatchesForTagProject(projectID = 204, batchID = 0)) %>%
  #   expect_s3_class("data.frame")
  # expect_gt(nrow(s), 0)
  
  #srvBatchesForReceiverDeprecated
  expect_silent(s <- srvBatchesForReceiverDeprecated(217)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  #srvBatchesForTagDeprecated
  expect_silent(s <- srvBatchesForTagProjectDeprecated(1)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvDeviceIDForReceiver
  expect_silent(s <- srvDeviceIDForReceiver(serno = "CTT-5031194D3168")) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvGPSForAll - deviceID = 6115; CTT-5031194D3168
  expect_silent(s <- srvGPSForAll(gpsID = 0)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvGPSForReceiver - deviceID = 6115; CTT-5031194D3168
  expect_silent(s <- srvGPSForReceiver(batchID = 476443)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvGPSForTagProject
  expect_silent(s <- srvGPSForTagProject(projectID = 4, batchID = 476443)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvHitsForReceiver
  expect_silent(s <- srvHitsForReceiver(batchID = 476443, hitID = 0)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvHitsForTagProject
  expect_silent(s <- srvHitsForTagProject(projectID = 4, batchID = 476443)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvMetadataForReceivers
  d <- srvDeviceIDForReceiver("CTT-5031194D3168")$deviceID
  expect_silent(s <- srvMetadataForReceivers(deviceIDs = d)) %>%
    expect_type("list")
  expect_named(s, c("recvDeps", "antDeps", "projs"))
  expect_gt(nrow(s$recvDeps), 0)
  expect_gt(nrow(s$antDeps), 0)
  expect_gt(nrow(s$projs), 0)
  
  # srvMetadataForTags
  expect_silent(s <- srvMetadataForTags(motusTagIDs = 29876)) %>%
    expect_type("list")
  expect_named(s, c("tags", "tagDeps", "tagProps", "species", "projs"))
  expect_gt(nrow(s$tags), 0)
  expect_gt(nrow(s$tagDeps), 0)
  expect_s3_class(s$tagProps, "data.frame") # might be empty
  expect_gt(nrow(s$species), 0)
  expect_gt(nrow(s$projs), 0)
  
  # srvNodes
  expect_silent(s <- srvNodes(projectID = 207, batchID = 1019183)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvProjectAmbiguitiesForTagProject - *****************************
  expect_silent(s <- srvProjectAmbiguitiesForTagProject(projectID = 176)) %>%
    expect_s3_class("data.frame")
  expect_equal(nrow(s), 0)  ## WHAT IS THIS, EXACTLY?
  
  # srvPulseCountsForReceiver - CTT-5031194D3168
  # expect_silent(s <- srvPulseCountsForReceiver(batchID = 40570, ant = 0)) %>%
  #   expect_s3_class("data.frame")
  # expect_gt(nrow(s), 0)
  
  # srvReceiversForProject
  # expect_silent(s <- srvReceiversForProject(projectID = 204)) %>%
  #   expect_s3_class("data.frame")
  # expect_gt(nrow(s), 0)
  
  # srvRecvMetadataForProjects
  expect_silent(s <- srvRecvMetadataForProjects(projectIDs = 213)) %>%
    expect_type("list")
  expect_named(s, c("recvDeps", "antDeps", "nodeDeps", "projs"))
  expect_gt(nrow(s$recvDeps), 0)
  expect_true(all(s$recvDeps$projectID == 213))
  expect_gt(nrow(s$antDeps), 0)
  expect_gt(nrow(s$nodeDeps), 0)
  expect_gt(nrow(s$projs), 0)
  
  expect_silent(s <- srvRecvMetadataForProjects(projectIDs = NULL)) %>%
    expect_type("list")
  expect_named(s, c("recvDeps", "antDeps", "nodeDeps", "projs"))
  expect_gt(nrow(s$recvDeps), 0)
  expect_gt(length(unique(s$recvDeps$projectID)), 10)
  expect_gt(nrow(s$antDeps), 0)
  expect_gt(nrow(s$nodeDeps), 0)
  expect_gt(nrow(s$projs), 0)
  
  # srvRunsForReceiver - CTT-5031194D3168
  # expect_silent(s <- srvRunsForReceiver(batchID = 1582469, runID = 0)) %>%
  #   expect_s3_class("data.frame")
  # expect_gt(nrow(s), 0)
  
  # srvRunsForTagProject
  expect_silent(s <- srvRunsForTagProject(projectID = 4, batchID = 120474)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvSizeOfUpdateForReceiver
  expect_silent(s <- srvSizeOfUpdateForReceiver(deviceID = 217, batchID = 0)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  
  # srvSizeOfUpdateForTagProject
  # expect_silent(s <- srvSizeOfUpdateForTagProject(projectID = 204, batchID = 0)) %>%
  #   expect_s3_class("data.frame")
  # expect_gt(nrow(s), 0)
  
  # srvTagMetadataForProjects
  expect_silent(s <- srvTagMetadataForProjects(projectIDs = 25)) %>%
    expect_type("list")
  expect_gt(nrow(s$tags), 0)
  expect_true(all(s$tags$projectID == 25))
  expect_gt(nrow(s$tagDeps), 0)
  #expect_gt(nrow(s$tagProps), 0)
  expect_gt(nrow(s$species), 0)
  expect_gt(nrow(s$projs), 0)
  
  expect_silent(s <- srvTagMetadataForProjects(projectIDs = NULL)) %>%
    expect_type("list")
  expect_gt(nrow(s$tags), 0)
  expect_gt(length(unique(s$tags$projectID)), 10)
  expect_gt(nrow(s$tagDeps), 0)
  expect_gt(nrow(s$tagProps), 0)
  expect_gt(nrow(s$species), 0)
  expect_gt(nrow(s$projs), 0)
  
  # srvTagsForAmbiguities
  expect_silent(s <- srvTagsForAmbiguities(ambigIDs = -56)) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
  expect_silent(s <- srvTagsForAmbiguities(ambigIDs = c(-56, -106))) %>%
    expect_s3_class("data.frame")
  expect_gt(nrow(s), 0)
})

test_that("tagme() errors appropriately", {
  skip_on_cran()
  
  sample_auth()
  
  expect_error(expect_message(tagme(projRecv = 10, new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "You do not have permission")
  
  expect_error(expect_message(tagme(projRecv = "CTT-5031194D3168", 
                                    new = TRUE, update = TRUE), 
                              "updateMotusDb"),
               "Either") #...
  unlink("project-10.motus")
})


# Projects downloads ---------------------------------------
test_that("tagme() downloads data - Projects", {
  skip_on_cran()
  
  sample_auth()
  
  expect_message(tags <- tagme(projRecv = 176, new = TRUE, update = TRUE)) %>%
    expect_s4_class("SQLiteConnection")
  disconnect(tags)
  unlink("project-176.motus")
})


# Receivers download ------------------------------------------------------
test_that("tagme() downloads data - Receivers", {
  skip_on_cran()
  skip_if_no_auth()
  
  unlink("SG-3115BBBK1127.motus")
  expect_message(t <- tagme("SG-3115BBBK1127", new = TRUE, update = TRUE)) %>%
    expect_s4_class("SQLiteConnection")
  disconnect(t)
  unlink("SG-3115BBBK1127.motus")
})


# Projects countOnly = TRUE ---------------------------------------------------
test_that("tagme with countOnly (tellme) - Projects", {
  skip_on_cran()
  sample_auth()
  
  unlink("project-176.motus")
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), 
            ".")
  
  expect_silent(tagme(projRecv = 176, new = FALSE, 
                      update = TRUE, countOnly = TRUE)) %>%
    expect_is("data.frame")
  
  expect_silent(tellme(projRecv = 176, new = FALSE)) %>%
    expect_is("data.frame")
  
  unlink("project-176.motus")
})

# Receivers countOnly = TRUE ---------------------------------------------------
test_that("tagme with countOnly (tellme) - Receivers", {
  skip_on_cran()
  skip_if_no_auth()
  
  unlink("SG-3115BBBK1127.motus")
  expect_silent(tellme("SG-3115BBBK1127", new = TRUE)) %>%
    expect_is("data.frame")
  unlink("SG-3115BBBK1127.motus")
})


# Timeouts ----------------------------------------------------------------
test_that("srvQuery handles time out graciously", {
  
  sample_auth()
  
  # https://stackoverflow.com/questions/100841/artificially-create-a-connection-timeout-error
  expect_message(
    expect_error(srvQuery(API = motus_vars$API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT, 
                          params = list(projectID = 176),
                          url = motus_vars$dataServerURL, timeout = 0.01),
                 "The server is not responding"),
    "The server did not respond within 0.01s. Trying again...")
})


# srvAuth errors ----------------------------------------------------------
test_that("srvAuth handles errors informatively", {
  motusLogout()
  sessionVariable(name = "userLogin", val = "motus.samp")
  sessionVariable(name = "userPassword", val = "motus.samp")
  
  expect_error(srvAuth(), "Authentication failed")
})

test_that("metadata()", {
  skip_on_cran()
  sample_auth()
  
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  tags <- tagme(176, new = FALSE, update = FALSE)
  expect_message(metadata(tags), "Loading complete")
  
  expect_message(metadata(tags, projectIDs = 45), "Loading complete")
  disconnect(tags)
  unlink("project-176.motus")
})

# srvAuth package version --------------------------------------------------

test_that("srvAuth errors/warns/passes on package version", {
  sample_auth()
  expect_silent(srvAuth())
  expect_true(!is.null(motus_vars$currentPkgVersion))
    
  v <- package_version(motus_vars$currentPkgVersion)
  v <- c(v, v, v)
  v[[c(1,1)]] <- as.numeric(v[[c(1,1)]]) - 1
  v[[c(3,1)]] <- as.numeric(v[[c(3,1)]]) + 1
  v <- as.character(v)
  
  with_mock("motus:::pkg_version" = mockery::mock(v[1]), 
            expect_warning(srvAuth()))
  with_mock("motus:::pkg_version" = mockery::mock(v[2]), 
            expect_silent(srvAuth()))
  with_mock("motus:::pkg_version" = mockery::mock(v[3]), 
            expect_silent(srvAuth()))
})
options(o)