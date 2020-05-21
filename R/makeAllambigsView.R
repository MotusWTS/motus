#' Create a virtual table that transposes the tagAmbig table
#'
#' Creates a virtual table (really a 'view') in a motus database that converts
#' the list of tags associated with ambiguous detections from columns to rows
#' this is mainly used by the alltags view to expand the detections records
#' showing each tag in addition to the ambigID
#'
#' @param db dplyr src_sqlite to detections database
#' @param name character scalar; name for the virtual table.
#'     Default: 'allambigs'.
#'
#' @return a dplyr::tbl which refers to the newly-created virtual table.
#' By default, the columns in the virtual table are:
#' \itemize{
#'    \item{ambigID} unique ID linking ambiguous tag detections
#'    \item{motusTagID} unique motus ID for this physical tag
#' }
#'
#' @note The new virtual table replaces any previous virtual table by the same
#' name in \code{db}.  The virtual table is an SQL VIEW, which will persist in \code{db}
#' across R sessions.
#'
#' @noRd
#'
makeAllambigsView = function(db, name="allambigs") {
    query = paste0("CREATE VIEW ", name, " AS
SELECT ambigID, motusTagID1 as motusTagID FROM tagAmbig where motusTagID1 is not null
UNION SELECT ambigID, motusTagID2 as motusTagID FROM tagAmbig where motusTagID2 is not null
UNION SELECT ambigID, motusTagID3 as motusTagID FROM tagAmbig where motusTagID3 is not null
UNION SELECT ambigID, motusTagID4 as motusTagID FROM tagAmbig where motusTagID4 is not null
UNION SELECT ambigID, motusTagID5 as motusTagID FROM tagAmbig where motusTagID5 is not null
UNION SELECT ambigID, motusTagID6 as motusTagID FROM tagAmbig where motusTagID6 is not null
")
    DBI::dbExecute(db$con, paste0("DROP VIEW IF EXISTS ", name))
    DBI::dbExecute(db$con, query)
    return(dplyr::tbl(db, name))
}
