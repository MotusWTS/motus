#' Add/update all batch activity
#' 
#' Download or resume a download of the `activityAll` table in an existing Motus
#' database. Batch activity refers to the number of hits detected during a given
#' batch. Batches with large numbers of hits may indicate interference and thus
#' unreliable hits.
#'
#' @param src src_sqlite object representing the database
#' @param resume Logical. Resume a download? Otherwise the `activityAll` table is
#'   removed and the download is started from the beginning.
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
#' # Get all activity
#' \dontrun{sql.motus <- activityAll(sql.motus)}
#' 
#' # Access 'activityAll' table
#' library(dplyr)
#' a <- tbl(sql.motus, "activityAll")
#'   
#' # If interrupted and you want to resume
#' \dontrun{sql.motus <- activityAll(sql.motus, resume = TRUE)}
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