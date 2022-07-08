#' Update all metadata
#' 
#' Updates the entire metadata for receivers and tags from Motus server.
#' Contrary to tagme, this function retrieves the entire set of metadata for
#' tags and receivers, and not only those pertinent to the detections in your
#' local file.
#'
#' @param src SQLite connection (result of `tagme(XXX)` or
#'   `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`)
#' @param projectIDs optional integer vector of Motus projects IDs for which
#'   metadata should be obtained; default: NULL, meaning obtain metadata for all
#'   tags and receivers that your permissions allow.
#' @param replace logical scalar; if TRUE (default), existing data replace the
#'   existing metadata with the newly acquired ones.
#' @param delete logical scalar; Default = FALSE. if TRUE, the entire metadata
#'   tables are cleared (for all projects) before re-importing the metadata.
#' 
#' @seealso \code{\link{tagme}} provides an option to update only the metadata
#'   relevant to a specific project or receiver file.
#'
#' @export
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
#' # Add extended metadata to your file
#' \dontrun{metadata(sql.motus)}
#'   
#' # Access different metadata tables
#' library(dplyr)
#' tbl(sql.motus, "species")
#' tbl(sql.motus, "projs")
#' tbl(sql.motus, "tagDeps")
#' # Etc.
#'   


metadata <- function(src, projectIDs = NULL, replace = TRUE, delete = FALSE) {
  check_src(src)
  
   if (delete) {
      message("Deleting local copy of Motus metadata")
      DBI_Execute(src, "DELETE FROM species")
      DBI_Execute(src, "DELETE FROM projs")
      DBI_Execute(src, "DELETE FROM tagDeps")
      DBI_Execute(src, "DELETE FROM tagProps")
      DBI_Execute(src, "DELETE FROM tags")
      DBI_Execute(src, "DELETE FROM antDeps")
      DBI_Execute(src, "DELETE FROM recvDeps")
      DBI_Execute(src, "DELETE FROM recvs")
   }
   
   message("Loading complete Motus metadata")
   if (!is.null(projectIDs)) message(glue::glue(
     "Project # ", glue::glue_collapse(projectIDs, sep = ", ")))

   ## get metadata for tags, their deployments, and species names
   tmeta <- srvTagMetadataForProjects(projectIDs = projectIDs)
   dbInsertOrReplace(src, "tags", tmeta$tags, replace)
   dbInsertOrReplace(src, "tagDeps", tmeta$tagDeps, replace)
   dbInsertOrReplace(src, "tagProps", tmeta$tagProps, replace)
   dbInsertOrReplace(src, "species", tmeta$species, replace)
   dbInsertOrReplace(src, "projs", tmeta$projs, replace)
   ## update tagDeps.fullID
   DBI_Execute(
     src, 
     "UPDATE tagDeps SET fullID = (",
     "  SELECT printf('%s#%s:%.1f@%g(M.%d)', t3.label, t2.mfgID, t2.bi, t2.nomFreq, t2.tagID) ",
     "  FROM tags AS t2 JOIN projs AS t3 ON t3.id = tagDeps.projectID ",
     "  WHERE t2.tagID = tagDeps.tagID ",
     "  LIMIT 1)")

   ## get metadata for receivers and their antennas
   rmeta <- srvRecvMetadataForProjects(projectIDs)
   dbInsertOrReplace(src, "recvDeps", rmeta$recvDeps, replace)
   dbInsertOrReplace(src, "recvs", rmeta$recvDeps[,c("deviceID", "serno")], replace)
   dbInsertOrReplace(src, "antDeps", rmeta$antDeps, replace)
   dbInsertOrReplace(src, "nodeDeps", rmeta$nodeDeps, replace)
   dbInsertOrReplace(src, "projs", rmeta$projs, replace)
   
   message("Done")
}
