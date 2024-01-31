#' Fetch and use data from the Motus Wildlife Tracking System
#'
#' `motus` is an R package for retrieving telemetry data from the Motus
#' Wildlife Tracking System \url{https://motus.org}.
#' 
#' For a detailed walk-though and instructions check out the 
#' [walk-throughs and articles](https://motuswts.github.io/motus/)!
#' 
#' Commonly used functions:
#'
#' 1. Download telemetry data
#'     - [tagme()]
#'     - [tellme()]
#'     - [metadata()]
#'     - [checkVersion()]
#'
#' 2. Create data filters
#'     - [listRunsFilters()]
#'     - [getRunsFilters()]
#'     - [createRunsFilter()]
#'     - [writeRunsFilter()]
#'     - [deleteRunsFilter()]
#'
#' 3. Summarize data
#'     - [tagSum()]
#'     - [tagSumSite()]
#'     - [simSiteDet()]
#'     - [siteSum()]
#'     - [siteSumDaily()]
#'     - [siteTrans()]
#'    
#' 4. Plot data
#'     - [plotAllTagsCoord()]
#'     - [plotAllTagsSite()]
#'     - [plotDailySiteSum()]
#'     - [plotRouteMap()]
#'     - [plotSite()]
#'     - [plotSiteSig()]
#'     - [plotTagSig()]
#'    
#' 5. Sunrises and sets
#'     - [sunRiseSet()]
#'     - [timeToSunriset()]
#'
#'
#' @references
#' Motus Wildlife Tracking System \url{https://motus.org}
#'
#'
#' @docType package
#' @name motus
NULL

# .onAttach <- function(libname, pkgname) {
#   packageStartupMessage("motus v", utils::packageVersion("motus"), "\n",
#                         "Database connections have been updated.\nIf you ",
#                         "use `XXX$con` notation, note that the `$con` is no ",
#                         "longer required.\n",
#                         "Release notes: https://motuswts.github.io/motus/news")
# }