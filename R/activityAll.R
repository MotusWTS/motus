#' Add/update all batch activity
#' 
#' Download or resume a download of the `activityAll` table in an existing Motus
#' database. Batch activity refers to the number of hits detected during a given
#' batch. Batches with large numbers of hits may indicate interference and thus
#' unreliable hits.
#'
#' @inheritParams args
#'
#' @examples
#' # Download sample project 176 to .motus database (username/password are "motus.sample")
#' \dontrun{sql_motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # Or use example data base in memory
#' sql_motus <- tagmeSample()
#'   
#' # Get all activity
#' \dontrun{sql_motus <- activityAll(sql_motus)}
#' 
#' # Access 'activityAll' table
#' library(dplyr)
#' a <- tbl(sql_motus, "activityAll")
#'   
#' # If interrupted and you want to resume
#' \dontrun{sql_motus <- activityAll(sql_motus, resume = TRUE)}
#'
#' @export

activityAll <- function(src, resume = FALSE) {
  
  pageInitial <- function(batchID, projectID) srvActivityForAll(batchID = batchID)
  
  pageForward <- function(b, batchID, projectID) {
    # Page forward
    ant <- b$ant[nrow(b)]
    hourBin <- b$hourBin[nrow(b)]
    
    # Try again
    srvActivityForAll(batchID = batchID, 
                      ant = ant, hourBin = hourBin) 
  }
  
  pageDataByReturn(src, table = "activityAll", resume = resume,
                   pageInitial = pageInitial, pageForward = pageForward)
  
}