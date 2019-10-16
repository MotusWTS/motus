# Steps/Commands to run before a package release -----------------------------

## Install required packages (if they don't already exist)
pkgs <- c("DBI", "dplyr", "dbplyr", "httr", "geosphere", "ggplot2", "gridExtra",
          "jsonlite", "lubridate", "magrittr", "maptools", "methods", "purrr",
          "rlang", "RSQLite", "stringr", "tidyr", "ggmap", "RCurl", "roxygen2",
          "spelling", "testthat")
pkgs_to_install <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
if(length(pkgs_to_install)) install.packages(pkgs_to_install)


## Update internal data files
source("data-raw/updatesql.R")
source("data-raw/sample_data.R")


## Documentation
# - Update NEWS


## Check spelling
dict <- hunspell::dictionary('en_CA')
devtools::spell_check() # Fix and re-run docs as needed
spelling::update_wordlist() # All remaining words will be added to the ignore WORDLIST file


## Finalize package version
# - Update DESCRIPTION - package version
# - Update .onLoad - API version
v <- "3.0.0"

## Checks
devtools::check(run_dont_test = TRUE)   # Local, run long-running examples

system("cd ..; R CMD build motus")
system(paste0("cd ..; R CMD check motus_", v, ".tar.gz"))
system(paste0("cd ..; R CMD check motus_", v, ".tar.gz --as-cran"))

rhub::check_on_macos(show_status = FALSE)
rhub::check_on_windows(show_status = FALSE)
rhub::check_for_cran(show_status = FALSE)

## Windows checks (particularly if submitting to CRAN)
devtools::check_win_release() # Win builder
devtools::check_win_devel()
devtools::check_win_oldrelease()


## Note: non-ASCII files found
# Find them

problems <- data.frame(file = list.files(recursive = TRUE, full.names = TRUE),
                       problem = as.character(NA), stringsAsFactors = FALSE)
problems <- dplyr::as_tibble(problems)
for(i in 1:nrow(problems)) {
  p <- tools::showNonASCIIfile(file = problems$file[i])
  if(length(p) > 0) problems$problem[i] <- as.list(p)
}
problems <- dplyr::mutate(problems, yes = purrr::map_lgl(problem, ~length(na.omit(.)) > 0)) %>%
  dplyr::filter(yes)

## Push to GitHub


## Check Reverse Dependencies (are there any?)
#tools::dependsOnPkgs("naturecounts")
#devtools::revdep()


## Push to master branch (pull request, etc.)


## Actually release it (manually)
# - Create signed release on github
# - Add NEWS to release details
