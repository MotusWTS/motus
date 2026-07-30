#' Skip if not testing locally with authorization
#' 
#' All testthat tests that require a personal user account are prefaced with
#' this skip function. 
#' 
#' The credentials for a personal user account (`MOTUS_USER` and
#' `MOTUS_PASSWORD`) should be stored in the users .Renviron file (generally
#' found in the users Home, e.g., on linux /home/user/ which is loaded on R
#' startup. If the credentials are not found, the tests are skipped.
#' 
#' @noRd

skip_if_no_auth <- function() {
  if (!have_auth()) {
    testthat::skip("No authentication available")
  } else {
    local_auth()
  }
}


skip_if_no_file <- function(file, system = TRUE, copy = FALSE) {
  if(system) file <- system.file("extdata", file, package = "motus")
  if(!file.exists(file)) {
    testthat::skip("File not available")
  }
  if(copy) file.copy(file, ".")
}

skip_if_no_server <- function() {
  sample_auth()
  srvTimeout(5)
  
  srv <- suppressMessages(try(
    httr::GET(file.path(motus_vars$dataServerURL, "api_info"), 
              httr::timeout(srvTimeout()[[1]])), silent = TRUE))
  if(inherits(srv, "try-error")) {
    srv <- suppressMessages(try(
      httr::GET(file.path(motus_vars$dataServerURL, "api_info"), 
                httr::timeout(srvTimeout()[[1]])), silent = TRUE))
    if(inherits(srv, "try-error")) {
      testthat::skip("Server Offline")
    }
  }
  srvTimeout(reset = TRUE)
}

is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}

set_testing <- function(set = TRUE) {
  if(set) Sys.setenv(TESTTHAT = "true")
  if(!set) Sys.unsetenv("TESTTHAT")
}

#' Create testing data
#' 
#' @param type Character. Project or Receiver
#'
#' @return In memory test database.
#' @export
#'
#' @examples
#' # Explore the sample data
#' tags <- tagmeSample()
#' dplyr::tbl(tags, "activity")
#' dplyr::tbl(tags, "alltags")

test_db <- function(type) {

  if(type == "project") {
    projRecv <- 999 
  } else {
    projRecv <- "CTT-6CA25D375881"
    deviceID <- 9999
  }

  dbname <- getDBFilename(projRecv, tempdir())
  if(file.exists(dbname)) file.remove(dbname)
  
  t <- DBI::dbConnect(RSQLite::SQLite(), dbname)
  
  t <- ensureDBTables(t, projRecv, deviceID = deviceID)
  t <- test_data(t, 20)
  DBI::dbRemoveTable(t, "admInfo")
  t <- ensureDBTables(t, projRecv)

  # Fake deprecated batches
  dep <- dplyr::tbl(t, "deprecated") %>% dplyr::collect() %>% dplyr::slice(1:5)
  dep$batchID <- sample(dplyr::tbl(t, "batches") %>% dplyr::pull(.data$batchID), nrow(dep))
  dbInsertOrReplace(t, "deprecated", dep)

  t
}

test_data <- function(src, n) {
  tbls <- DBI::dbListTables(src)
  tbls <- tbls[!tbls %in% c("alltags", "allambigs", "alltagsGPS", "allruns", "allrunsGPS")]
  
  batches <- sample(100000:500000, n)
  for (i in tbls) {
    t <- dplyr::tbl(src, i) |>
      dplyr::collect()

    d <- purrr::map(seq_len(n), \(x) test_row(t, b = batches)) |>
      purrr::list_rbind()

    if(i == "batches") d$batchID <- batches

    dbInsertOrReplace(src, i, d)
  }

  src
}

test_row <- function(df, b) {
  d <- list(
    integer = sample(1:999999999, 1),
    numeric = rnorm(1, sample(1:200, 1), sd = sample(1, 5, 1)),
    character = sample(letters, sample(1:40, 1), replace = TRUE) %>%
      paste0(collapse = ""),
    factor = sample(
      factor(
        c("small", "medium", "large"),
        levels = c("small", "medium", "large")
      ),
      1
    )
  )

  special <- list(
    "removed" = 0,
    "motusFilter" = sample(0:1, 1),
    "batchID" = sample(b, 1),
    "batchIDbegin" = sample(b, 1)
  )

  df <- purrr::map(df, \(n) d[[class(n)]]) |>
    as.data.frame()
  for (s in names(special)) {
    if (s %in% names(df)) df[s] <- special[s]
  }
  df
}