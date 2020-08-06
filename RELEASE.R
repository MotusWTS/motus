
# Notes -------------------------------------------------------------------

# The motus project works with three(ish) main branches:
#
# - master - currently released version of motus (e.g., v3.0.0)
# - betaX - minor work for the next minor release (e.g., beta3 = v3.0.1)
# - sandbox - major work for the next major release (e.g., v4.0.0)
#
# Merges may occur as follows:  
#
#  beta --> master
#  beta --> sandbox
#  sandbox --> master
# 
# When merging changes to master: 
# 
# - Make changes, push changes, test changes (beta/sandbox branch)
# - git checkout master  (master branch)
# - git merge betaX --no-ff --no-commit  (master branch)
# - Revert API url to (i.e. should be main url, not point to beta/sandbox APIs)
# - Committ changes as merge with betaX/sandbox
#
# # When merging changes in beta to sandbox: 
# 
# - Make changes, push changes, test changes (beta branch)
# - git checkout sandbox  (sandbox branch)
# - git merge betaX --no-ff --no-commit  (sandbox branch)
# - Revert API url to (i.e. should be sandbox url, not point to beta)
# - Revert VERSION number (i.e. keep sandbox version, not beta version)
# - Committ changes as merge with betaX

# Steps/Commands to run before a package release -----------------------------

## Install required packages (if they don't already exist)
pkgs <- c("DBI", "dplyr", "dbplyr", "httr", "geosphere", "ggplot2", "gridExtra",
          "jsonlite", "lubridate", "magrittr", "maptools", "methods", "purrr",
          "rlang", "RSQLite", "stringr", "tidyr", "ggmap", "RCurl", "roxygen2",
          "spelling", "testthat")
pkgs_to_install <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
if(length(pkgs_to_install)) install.packages(pkgs_to_install)


## IF MERGING SANDBOX
# - Make sure that updatesql.R updates unique to sandbox have a date later than
#   beta updates (otherwise they won't trigger)

## Update internal data files
set_testing(set = FALSE) # Make sure to download full sets
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
v <- "3.1.0"
v <- packageVersion("motus") # If dev version loaded with devtools::load_all()

## Checks
devtools::check(run_dont_test = TRUE)   # Local, run long-running examples
devtools::check(run_dont_test = FALSE)


system("cd ..; R CMD build motus")
system(paste0("cd ..; R CMD check motus_", v, ".tar.gz"))
system(paste0("cd ..; R CMD check motus_", v, ".tar.gz --as-cran"))

rhub::check_on_linux(show_status = FALSE)
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

## Push to master branch (pull request, etc.)


## Actually release it (manually)
# - Create signed release on github
# - Add NEWS to release details
