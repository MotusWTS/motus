
# Notes -------------------------------------------------------------------

# The motus project works with three(ish) main branches:
#
# - main - currently released version of motus (e.g., v3.0.0)
# - hotfix/dev - minor work using current API version (e.g., v3.0.0.9000)
# - beta - minor work for the next minor API release (e.g., v3.0.0.9900)
# - sandbox - major work for the next major API release (e.g., v3.0.0.9990)
#
# Merges may occur as follows:  
#
#  beta --> main
#  beta --> sandbox
#  sandbox --> main
#
#  hotfix --> main
#  hotfix --> beta
#  hotfix --> sandbox
# 
# When merging changes to main: 
# 
# - Change api url to https://motus.org/api     (in z.onLoad.R)
# - Change version to correct (non-dev) version (in DESCRIPTION)
# - Test changes (beta/sandbox branch)
# - Push
# - GitHub pull request, make sure tests pass, merge
# - Sign release
#
# # When merging changes from main to sandbox:
#
# - git checkout sandbox  (sandbox branch)
# - git merge main --no-ff --no-commit  (sandbox branch)
# - Revert API url to (i.e. should be sandbox url, not point to main)
# - Revert VERSION number (i.e. keep sandbox version, not main version)
# - Commit changes as merge with main
# - Check dates on updatesql, sandbox changes should be 'later' than beta
# 
# # When merging changes in beta to sandbox: 
# 
# - git checkout sandbox  (sandbox branch)
# - git merge betaX --no-ff --no-commit  (sandbox branch)
# - Revert API url to (i.e. should be sandbox url, not point to beta)
# - Revert VERSION number (i.e. keep sandbox version, not beta version)
# - Committ changes as merge with betaX
#
# # After releasing a new version (i.e. all changes into main)
# 
# - Delete beta and sandbox locally and on GitHub
# - Create beta and sandbox from main
# - Update versions (X.X.X.9900 and X.X.X.9990)
# - Update apis (in z.onLoad.R) to https://beta.motus.org/api and https://sandbox.motus.org/api
# - Add `# motus beta dev` and `# motus sandbox dev` headings to NEWS


## Install required packages (if they don't already exist)
remotes::install_deps(dependencies = TRUE)


## Update internal data files ------------------------------------------------

# - If merging sandbox - make sure that data-raw/updatesql.R updates unique to 
#   sandbox have a date later than beta updates (otherwise they won't trigger)


# Load all functions: devtools::load_all() or Ctrl-Shift-L
set_testing(set = FALSE) # Make sure to download full sets
source("data-raw/internal_data.R")
source("data-raw/sample_data.R")


## Documentation ----------------------------------------------------------
# - Update NEWS


## Check spelling ---------------------------------------------------------
dict <- hunspell::dictionary('en_CA')
devtools::spell_check() # Fix and re-run docs as needed
spelling::update_wordlist() # All remaining words will be added to the ignore WORDLIST file

# Check/update URLS
urlchecker::url_check()


## Finalize package version -----------------------------------------------
# - Update DESCRIPTION - package version
# - Update .onLoad - API version
#v <- "6.0.1"
#v <- packageVersion("motus") # If dev version loaded with devtools::load_all()

## Checks ------------------------------------------------------------------

goodpractice::gp(checks = stringr::str_subset(goodpractice::all_checks(), 
                                              "rcmdcheck|covr|cyclocomp", negate = TRUE))

# Quick check without examples or tests
devtools::check(args = c("--no-tests", "--no-examples"))

devtools::check(run_dont_test = TRUE)   # Local, run long-running examples
devtools::check(run_dont_test = FALSE)


system("cd ..; R CMD build motus")
system(paste0("cd ..; R CMD check motus_", v, ".tar.gz"))
system(paste0("cd ..; R CMD check motus_", v, ".tar.gz --as-cran"))

rhub::check_on_linux(paste0("../motus_", v, ".tar.gz"), show_status = FALSE)
rhub::check_on_macos(paste0("../motus_", v, ".tar.gz"), show_status = FALSE)
rhub::check_on_windows(paste0("../motus_", v, ".tar.gz"), show_status = FALSE)
rhub::check_for_cran(paste0("../motus_", v, ".tar.gz"), show_status = FALSE)

## Windows checks (particularly if submitting to CRAN)
devtools::check_win_release() # Win builder
devtools::check_win_devel()
devtools::check_win_oldrelease()



## Push to GitHub ----------------------------------------------------

## Push to main branch (pull request, etc.)

## Actually release it (manually) ----------------------------------
# - Create signed release on github using the NEWS 
usethis::use_github_release() 

## Update API package version to current (only for main) -----------
# - Must use personal access
srvAPIinfo()
srvQuery(API = "custom/update_pkg_version", params = list(pkgVersion = "6.1.0"))




## Test motus website (will be compiled online) ------------------------------

pkgdown::build_site(lazy = TRUE)
pkgdown::build_home()

# Testing themes
pkgdown::build_home_index()
pkgdown::init_site()

# TEsting specific articles
pkgdown::build_article("articles/06-exploring-data")
pkgdown::build_article("articles/01-introduction")
unlink("vignettes/articles/map-data/", recursive = TRUE)


## Find ASCII -------------------------------------------------------
# Note: non-ASCII files found
problems <- data.frame(file = list.files(recursive = TRUE, full.names = TRUE),
                       problem = as.character(NA), stringsAsFactors = FALSE)
problems <- dplyr::as_tibble(problems)
for(i in 1:nrow(problems)) {
  p <- tools::showNonASCIIfile(file = problems$file[i])
  if(length(p) > 0) problems$problem[i] <- as.list(p)
}
problems <- dplyr::mutate(problems, yes = purrr::map_lgl(problem, ~length(na.omit(.)) > 0)) %>%
  dplyr::filter(yes)


