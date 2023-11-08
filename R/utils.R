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
  srv <- suppressMessages(try(srvAuth(timeout = 1), silent = TRUE))
  if(inherits(srv, "try-error")) {
    srv <- suppressMessages(try(srvAuth(timeout = 1), silent = TRUE))
    if(inherits(srv, "try-error")) {
      testthat::skip("Server Offline")
    }
  }
}

is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}

set_testing <- function(set = TRUE) {
  if(set) Sys.setenv(TESTTHAT = "true")
  if(!set) Sys.unsetenv("TESTTHAT")
}

#' Test for local authorization
#' 
#' This is a helper function for testing and applying local authorizations when
#' available.
#' 
#' The credentials for a personal user account (`MOTUS_USER` and
#' `MOTUS_PASSWORD`) should be stored in the user's .Renviron file
#' (generally found in the users Home, e.g., on linux /home/user/ which is
#' loaded on R startup. If the credentials are found, they are applied and
#' TRUE is returned. Otherwise FALSE is returned.
#' 
#' @noRd

have_auth <- function() !identical(Sys.getenv("MOTUS_USER"), "")

local_auth <- function() {
  if(have_auth()) {
    suppressMessages(motusLogout())
    sessionVariable(name = "userLogin", val = Sys.getenv("MOTUS_USER"))
    sessionVariable(name = "userPassword", val = Sys.getenv("MOTUS_PASSWORD"))
  } else {
    message("No local authorization")
  }
}

sample_auth <- function() {
  suppressMessages(motusLogout())
  sessionVariable(name = "userLogin", val = "motus.sample")
  sessionVariable(name = "userPassword", val = "motus.sample")
}

# Is it a project or a receiver?
is_proj <- function(x) stringr::str_detect(x, "^[0-9]+$")

# Get project or receiver from source name
get_projRecv <- function(src) {
  check_src(src)
  projRecv <- basename(src@dbname)
  if(projRecv == ":memory:") {
    stop("Cannot use an in-memory data base for this operation (i.e. cannot use `tagmeSample()`)", 
         call. = FALSE)
  }
  if(stringr::str_detect(projRecv, "project-[0-9]+.motus")) {
    projRecv <- as.integer(stringr::str_extract(projRecv, "[0-9]+"))
  } else if(stringr::str_detect(projRecv, ".motus")) {
    projRecv <- stringr::str_remove(projRecv, ".motus")
  } else {
    stop("Database is not a recognized motus project", call. = FALSE)
  }
  projRecv
}



updatePkgVersion <- function(version) {
  srvUpdatePkgVersion(version)
}

#' Return accessible projects and receivers
#'
#' Return the projects and receivers which are accessible by the given
#' credentials
#'
#' @examples
#' \dontrun{
#' getAccess()
#' }
#' 
#' @export

getAccess <- function() {
  motus_vars$authToken # Prompt for authorization
  message("Projects: ", paste0(motus_vars$dataVersion, collapse = ", "), "\n",
          "Receivers: ", paste0(motus_vars$receivers, collapse = ", "))
}


#' Create an in-memory copy of sample tags data
#' 
#' For running examples and testing out motus functionality, it can be useful to
#' work with sample data set. You can download the most up-to-date copy of this
#' data yourself (to `project-176.motus`) with the username and password both
#' "motus.sample".
#' 
#' `sql_motus <- tagme(176, new = TRUE, update = TRUE)`
#' 
#' Or you can use this helper function to grab an in-memory copy bundled in this
#' package.
#' 
#' @param db Character. Name of sample data base to load. The sample data is
#'   "project-176.motus".
#'
#' @return In memory version of the sample database.
#' @export
#'
#' @examples
#' # Explore the sample data
#' tags <- tagmeSample()
#' dplyr::tbl(tags, "activity")
#' dplyr::tbl(tags, "alltags")

tagmeSample <- function(db = "project-176.motus") {
  sample <- DBI::dbConnect(
    RSQLite::SQLite(),
    system.file("extdata", db, package = "motus"))
  
  memory <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  
  RSQLite::sqliteCopyDatabase(sample, memory)
  memory
}

#' Internal function for use in docs
#'
#' @noRd
get_sample_data <- function() {
  sample_auth() # Use motus sample authorizations
  if(!dir.exists("./data/")) dir.create("./data/")
  message("Copying sample project")
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), 
            "./data/")
  message("Loading sample project")
  tagme(projRecv = 176, new = FALSE, update = TRUE, dir = "./data/")
}

disconnect <- function(src, warnings = FALSE) {
  if(!warnings) suppressWarnings(DBI::dbDisconnect(src))
  if(warnings) DBI::dbDisconnect(src)
}


# Faster than as.data.frame()
to_df <- function(x) {
  structure(x, class = "data.frame", row.names = seq_len(lengths(x[1])))
}