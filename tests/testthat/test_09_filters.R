test_that("SQL filters", {
  sample_auth()
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), ".")
  tags <- tagme(176, update = FALSE)
  
  df <- dplyr::tbl(tags, "alltags") %>%
    dplyr::filter(runID == max(runID, na.rm = TRUE)) %>%
    dplyr::collect()
    
  expect_warning(getRunsFilterID(tags, "test_filter"),
                 "There are no filters matching this name.")
  expect_warning(deleteRunsFilter(tags, "test_filter"),
                 "There are no filters matching this name.")
  
  expect_silent(createRunsFilter(tags, "test_filter", update = FALSE))
  expect_warning(createRunsFilter(tags, "test_filter", update = FALSE),
                 "Filter already exists")
  
  expect_silent(getRunsFilterID(tags, "test_filter")) %>%
    expect_equal(1)
  
  expect_silent(getRunsFilters(tags, "test_filter")) %>%
    expect_s3_class("tbl_sql")
  
  expect_silent(deleteRunsFilter(tags, "test_filter"))
  
  expect_error(writeRunsFilter(tags, filterName = "test_filter", df = df),
               "'df' must have at least columns")
  
  df$probability <- 1
  
  expect_message(writeRunsFilter(tags, filterName = "test_filter", df = df),
                 "Filter records saved")
  
  expect_silent(createRunsFilter(tags, "test_filter2", update = FALSE))
  expect_silent(getRunsFilterID(tags, "test_filter2")) %>%
    expect_equal(2)
  
  expect_silent(l <- listRunsFilters(tags)) %>%
    expect_s3_class("data.frame") %>%
    expect_length(6)
  expect_equal(nrow(l), 2)
  
  DBI::dbDisconnect(tags)
  unlink("project-176.motus")
})
  