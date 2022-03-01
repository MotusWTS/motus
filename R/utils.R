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


skip_if_no_file <- function(file) {
  if(!file.exists(file)) {
    testthat::skip("File not available")
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
  if (! inherits(src, "src_sql"))
    stop("src is not a dplyr::src_sql object", call. = FALSE)
  
  projRecv <- basename(src[[1]]@dbname)
  if(stringr::str_detect(projRecv, "project-[0-9]+.motus")) {
    projRecv <- as.numeric(stringr::str_extract(projRecv, "[0-9]+"))
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


requiredCols <- function(x, req, name = "data") {
  cols <- colnames(x)
  if(any(!req %in% cols)) {
    stop("Required columns/fields missing from '", name, "': ",
         paste0(req[!req %in% cols], collapse = ", "))
  }
}

get_sample_data <- function() {
  sample_auth() # Use motus sample authorizations
  unlink("project-176.motus")
  if(!dir.exists("./data/")) dir.create("./data/")
  message("Copying sample project")
  file.copy(system.file("extdata", "project-176.motus", package = "motus"), 
            "./data/")
  message("Loading sample project")
  tagme(projRecv = 176, new = FALSE, update = TRUE, dir = "./data/")
}