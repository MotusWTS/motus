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
  expect_equal(dplyr::filter(a, probability == 1) %>% collect(), 
               collect(g))
  expect_equal(dplyr::filter(a, probability == 0) %>% collect(), 
               collect(b))
  
  # Matches motusFilter results
  runs <- tbl(shorebirds_sql, "runs") %>%
    select(runID, batchID = batchIDbegin, motusFilter) %>%
    distinct() %>%
    collect()
  
  a <- a %>%
    mutate(motusFilter = as.integer(probability)) %>%
    select(runID, batchID, motusFilter) %>%
    distinct() %>%
    collect()
  
  expect_true(all_equal(runs, a))
})

test_that("Good/Bad runs change depending on parameters", {
  expect_silent(
    shorebirds_sql <- tagme(176, update = FALSE, 
                            dir = system.file("extdata", package = "motus")))
  
  # Expect run lengths to change if adjust the parameters
  expect_silent(a <- filterByActivity(shorebirds_sql, minLen = 10, maxLen = 15, return = "all"))
  expect_equal(filter(a, runLen <= 10) %>%
                 summarize(probability = sum(probability, na.rm = TRUE)) %>%
                 collect() %>% pull(probability),
               0)
  expect_equal(filter(a, runLen >= 15) %>%
                 summarize(probability = sum(probability == 0, na.rm = TRUE)) %>%
                 collect() %>% pull(probability),
               0)
  

  expect_silent(a <- filterByActivity(shorebirds_sql, minLen = 2, maxLen = 5, return = "all"))
  expect_equal(filter(a, runLen <= 2) %>%
                 summarize(probability = sum(probability, na.rm = TRUE)) %>%
                 collect() %>% pull(probability),
               0)
  expect_equal(filter(a, runLen >= 5) %>%
                 summarize(probability = sum(probability == 0, na.rm = TRUE)) %>%
                 collect() %>% pull(probability),
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