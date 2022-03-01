#' Fetch and use data from the Motus Wildlife Tracking System
#'
#' \code{motus} is an R package for retrieving telemetry data from the Motus
#' Wildlife Tracking System \url{http://motus.org}.
#' 
#' For a detailed walk-though and instructions check out the 
#' \href{https://motus.org/MotusRBook/}{Motus R Book}
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
#' Motus Wildlife Tracking System \url{http://motus.org}
#'
#'
#' @docType package
#' @name motus
NULL