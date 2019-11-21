#' Update motus sqlite file
#' 
#' Ensures that the motus sqlite file is up-to-date to support the current
#' version of the package. Relies on the \code{sql_versions} internal data frame
#' to run the SQL on the basis of date.
#' 
#' This function adds a new admInfo table in the motus sqlite file that keeps
#' track of the date at which the last correction was applied. The updateMotusDb
#' function only executes sql commands added since the last correction.
#' 
#' To insert a new version update modify and run the ./data-raw/updatesql.R
#' script to add new sql commands to the internal data frame.
#' 
#' \itemize{
#'   \item date: date at which the sql update record was added (default current
#'   timestamp)
#'   \item sql: sql string to execute (you should minimize the risk of database
#'   errors by using IF EXISTS or DROP as appropriate prior to your command)
#'   \item descr: description of the update, printed for the user during the
#'   update process
#' }
#'   
#' This function is called at the end of the \code{\link{ensureDBTables}}
#' function. i.e., it will be called each time that a motus file is opened.
#'
#' @param src sqlite database source
#' 
#' @author Denis Lepage \email{dlepage@@bsc-eoc.org}
#'
#' @noRd

updateMotusDb <- function(src) {

  # # Create and fill the admInfo table if it doesn't exist
  # DBI::dbExecute(src$con, paste0("CREATE TABLE IF NOT EXISTS admInfo ",
  #                                "(key VARCHAR PRIMARY KEY NOT NULL, value VARCHAR)"))
  # DBI::dbExecute(src$con, paste0("INSERT OR IGNORE INTO admInfo (key,value) ",
  #                                "VALUES('db_version',date('1970-01-01'))"))

  # Get the current src version
  src_version <- dplyr::tbl(src$con, "admInfo") %>%
    dplyr::pull(.data$db_version) %>%
    as.POSIXct(., tz = "UTC")

  update_versions <- dplyr::filter(sql_versions, date > src_version) %>%
    dplyr::arrange(.data$date)

  if (nrow(update_versions) > 0) {
    message(sprintf("updateMotusDb started (%d version update(s))", 
                    nrow(update_versions)))
    
    dates <- apply(update_versions, 1, function(row) {
      message(" - ", row["descr"], sep = "")

	    v <- unlist(strsplit(row["sql"], ";"))
	    l <- lapply(v, function(sql) {
	      if (sql != "") {

	        e <- try(DBI::dbExecute(src$con, sql), silent = TRUE)
	        if(class(e) == "try-error") { # Deal with errors
	          if(!stringr::str_detect(e, "duplicate column name: ")) {
	            stop(e)
	          }
	        }
	      }
	      sql
	    })	
      row["date"]
    })

    if (length(dates) > 0) dt <- dates[length(dates)]

    if (dt > src_version) {
      DBI::dbExecute(src$con, paste0("UPDATE admInfo set db_version = '",
                                    strftime(dt, "%Y-%m-%d %H:%M:%S"), "'"))
    }
  }
}
