context("Helper functions")


test_that("filterByActivity filters as expected", {
  expect_silent(
    shorebirds_sql <- tagme(176, update = FALSE, 
                            dir = system.file("extdata", package = "motus")))
  
  expect_silent(a <- filterByActivity(shorebirds_sql, return = "all")) %>%
    expect_is("tbl")
  expect_silent(g <- filterByActivity(shorebirds_sql)) %>%
    expect_is("tbl")
  expect_silent(b <- filterByActivity(shorebirds_sql, return = "bad")) %>%
    expect_is("tbl")
  
  # 'good' and 'bad' should be subsets of 'all'
  expect_equal(dplyr::filter(a, probability == 1) %>% dplyr::collect(), 
               dplyr::collect(g))
  expect_equal(dplyr::filter(a, probability == 0) %>% dplyr::collect(), 
               dplyr::collect(b))
  
  # Matches motusFilter results
  runs <- dplyr::tbl(shorebirds_sql, "runs") %>%
    dplyr::select(runID, batchID = batchIDbegin, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect()
  
  a <- a %>%
    dplyr::mutate(motusFilter = as.integer(probability)) %>%
    dplyr::select(runID, batchID, motusFilter) %>%
    dplyr::distinct() %>%
    dplyr::collect()
  
  expect_true(dplyr::all_equal(runs, a))
})

test_that("Good/Bad runs change depending on parameters", {
  expect_silent(
    shorebirds_sql <- tagme(176, update = FALSE, 
                            dir = system.file("extdata", package = "motus")))
  
  # Expect run lengths to change if adjust the parameters
  expect_silent(a <- filterByActivity(shorebirds_sql, minLen = 10, maxLen = 15, return = "all"))
  expect_equal(dplyr::filter(a, runLen <= 10) %>%
                 dplyr::summarize(probability = sum(probability, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  expect_equal(dplyr::filter(a, runLen >= 15) %>%
                 dplyr::summarize(probability = sum(probability == 0, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  

  expect_silent(a <- filterByActivity(shorebirds_sql, minLen = 2, maxLen = 5, return = "all"))
  expect_equal(dplyr::filter(a, runLen <= 2) %>%
                 dplyr::summarize(probability = sum(probability, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
  expect_equal(dplyr::filter(a, runLen >= 5) %>%
                 dplyr::summarize(probability = sum(probability == 0, na.rm = TRUE)) %>%
                 dplyr::collect() %>% dplyr::pull(probability),
               0)
})

test_that("Empty activity table stops", {
  file.copy(system.file("extdata", "project-176.motus", package = "motus"),
            ".")
  tags <- tagme(176, update = FALSE)
  
  # Empty activity
  DBI::dbExecute(tags$con, "DELETE FROM activity")
  expect_error(a <- filterByActivity(tags, return = "all"),
               "'activity' table is empty, cannot filter by activity")
  
  # No activity
  DBI::dbRemoveTable(tags$con, "activity")
  expect_error(a <- filterByActivity(tags, return = "all"),
               "'src' must contain at least tables 'activity', 'alltags',")
  file.remove("project-176.motus")
})