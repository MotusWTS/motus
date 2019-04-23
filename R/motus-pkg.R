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
#' \enumerate{
#'   \item Download telemetry data
#'   \itemize{
#'     \item \code{\link{tagme}()}
#'     \item \code{\link{tellme}()}
#'     \item \code{\link{metadata}()}
#'     \item \code{\link{checkVersion}()}
#'     }
#'
#'  \item Create data filters
#'  \itemize{
#'    \item \code{\link{listRunsFilters}()}
#'    \item \code{\link{getRunsFilters}()}
#'    \item \code{\link{getRunsFilterID}()}
#'    \item \code{\link{createRunsFilter}()}
#'    \item \code{\link{writeRunsFilter}()}
#'    \item \code{\link{deleteRunsFilter}()}
#'    }
#'
#'  \item Summarize data
#'  \itemize{
#'    \item \code{\link{tagSum}()}
#'    \item \code{\link{tagSumSite}()}
#'    \item \code{\link{simSiteDet}()}
#'    \item \code{\link{siteSum}()}
#'    \item \code{\link{siteSumDaily}()}
#'    \item \code{\link{siteTrans}()}
#'    }
#'    
#'  \item Plot data
#'  \itemize{
#'    \item \code{\link{plotAllTagsCoord}()}
#'    \item \code{\link{plotAllTagsSite}()}
#'    \item \code{\link{plotDailySiteSum}()}
#'    \item \code{\link{plotRouteMap}()}
#'    \item \code{\link{plotSite}()}
#'    \item \code{\link{plotSiteSig}()}
#'    \item \code{\link{plotTagSig}()}
#'    }
#'    
#'  \item Sunrises and sets
#'  \itemize{
#'    \item \code{\link{sunRiseSet}()}
#'    \item \code{\link{timeToSunriset}()}
#'    }
#' }
#'
#' We also include a practice data set:
#'
#'  \itemize{
#'    \item \code{\link{shorebirds}}
#'    }
#'
#'
#' @references
#' Motus Wildlife Tracking System \url{http://motus.org}
#'
#'
#' @docType package
#' @name motus
#' @aliases motus-package motus-pkg
NULL