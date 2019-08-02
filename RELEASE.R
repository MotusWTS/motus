# Steps/Commands to run before a package release -----------------------------

## Update internal data files
source("data-raw/updatesql.R")
source("data-raw/sample_data.R")

## Documentation
# Update NEWS

# Check spelling
dict <- hunspell::dictionary('en_CA')
devtools::spell_check()

## Finalize package version

## Checks
devtools::check(run_dont_test = TRUE)   # Local, run long-running examples

## Windows checks (particularly if submitting to CRAN)
devtools::check_win_release() # Win builder
devtools::check_win_devel()
devtools::check_win_oldrelease()

## Run in console
system("cd ..; R CMD build motus")
system("cd ..; R CMD check motus_1.5.0.tar.gz --as-cran")

## Push to github
## Check travis / appveyor

## Check Reverse Dependencies (are there any?)
#tools::dependsOnPkgs("naturecounts")
#devtools::revdep()

## Push to master branch

## Actually release it, create signed release on github
system("git tag -s v2.0.0 -m 'v2.0.0'")
system("git push --tags")

## Edit the release on GitHub and add the newest contents of the NEWS file
