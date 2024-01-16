#' Add/update all GPS points
#' 
#' Download or resume a download of the `gpsAll` table in an existing Motus
#' database. Batch activity refers to the number of hits detected during a given
#' batch. Batches with large numbers of hits may indicate interference and thus
#' unreliable hits.
#'
#' @inheritParams args
#'
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#'   
#' # Get all GPS points
#' \dontrun{sql_motus <- gpsAll(sql_motus)}
#' 
#' # Access 'gpsAll' table
#' library(dplyr)
#' g <- tbl(sql_motus, "gpsAll")
#'   
#' # gpsAll resumes a previous download by default
#' # If you want to delete this original data and do a fresh download, 
#' # use resume = FALSE
#' \dontrun{sql_motus <- gpsAll(sql_motus, resume = FALSE)}
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
