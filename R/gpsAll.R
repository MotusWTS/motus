#' Add/update all GPS points
#' 
#' Download or resume a download of the `gpsAll` table in an existing Motus
#' database. Batch activity refers to the number of hits detected during a given
#' batch. Batches with large numbers of hits may indicate interference and thus
#' unreliable hits.
#'
#' @param src src_sqlite object representing the database
#' @param resume Logical. Resume a download? Otherwise the `activity` table is
#'   removed and the download is started from the beginning.
#' 
#' @details This function is automatically run by the [tagme()] function with
#'   `resume = TRUE`. 
#'   
#'   If an `activity` table doesn't exist, it will be created prior to
#'   downloading. If there is an existing `activity` table, this will update the
#'   records.
#'
#' @examples
#' 
#' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#'   
#' # Get all GPS points
#' \dontrun{sql.motus <- gpsAll(sql.motus)}
#' 
#' # Access 'gpsAll' table
#' library(dplyr)
#' g <- tbl(sql.motus, "gpsAll")
#'   
#' # gpsAll resumes a previous download by default
#' # If you want to delete this original data and do a fresh download, 
#' # use resume = FALSE
#' \dontrun{sql.motus <- gpsAll(sql.motus, resume = FALSE)}
#'
#' @export

gpsAll <- function(src, resume = TRUE) {
  
  pageInitial <- function(returnID, projectID) srvGPSForAll(gpsID = returnID)
  
  pageForward <- function(b, returnID, projectID) {
    srvGPSForAll(gpsID = returnID) 
  }
  
  pageDataByReturn(src, table = "gpsAll", resume = resume, returnIDtype = "gpsID",
                   pageInitial = pageInitial, pageForward = pageForward)
  
}