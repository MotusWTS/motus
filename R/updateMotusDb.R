#' Update motus sqlite file
#' 
#' Ensures that the motus sqlite file is up-to-date to support the current
#' version of the package. Relies on the `sql_versions` internal data frame
#' to run the SQL on the basis of date.
#' 
#' This function adds a new `admInfo` table in the sqlite file that keeps track
#' of the date at which the last correction was applied. The `updateMotusDb()`
#' function only executes SQL commands added since the last correction.
#' 
#' To insert a new version update modify and run the `./data-raw/updatesql.R`
#' script to add new SQL commands to the internal data frame.
#' 
#' - `date`: date at which the SQL update record was added (default current
#'   timestamp)
#' - `sql`: SQL string to execute (you should minimize the risk of database
#'   errors by using IF EXISTS or DROP as appropriate prior to your command)
#' - `descr`: description of the update, printed for the user during the
#'   update process
#'   
#' This function is called at the end of the `ensureDBTables()`
#' function. i.e., it will be called each time that a motus file is opened.
#'
#' @param src sqlite database source
#'
#' @noRd

updateMotusDb <- function(src, quiet = FALSE) {

  # # Create and fill the admInfo table if it doesn't exist
  # DBI::dbExecute(src, paste0("CREATE TABLE IF NOT EXISTS admInfo ",
  #                                "(key VARCHAR PRIMARY KEY NOT NULL, value VARCHAR)"))
  # DBI::dbExecute(src, paste0("INSERT OR IGNORE INTO admInfo (key,value) ",
  #                                "VALUES('db_version',date('1970-01-01'))"))

  # Get the current src version
  src_version <- dplyr::tbl(src, "admInfo") %>%
    dplyr::pull(.data$db_version) %>%
    lubridate::ymd_hms(truncated = 3)

  update_versions <- dplyr::filter(sql_versions, date > src_version) %>%
    dplyr::arrange(.data$date)

  if (nrow(update_versions) > 0) {
    
    # Check if there are custom views to be concerned about
    checkViews(src, dplyr::pull(update_versions, "sql"))
    
    if(!quiet) message(msg_fmt("updateMotusDb started ({nrow(update_versions)} ",
                               "version update(s))"))
    
    dates <- apply(update_versions, 1, function(row) {
      if(!quiet) message(" - ", row["descr"], sep = "")
      
      v <- unlist(strsplit(row["sql"], ";"))
      l <- lapply(v, function(sql) {
        if (sql != "") {

	        e <- try(DBI_ExecuteAll(src, sql), silent = TRUE)
	        if(inherits(e, "try-error")) { # Deal with errors
	          if(!stringr::str_detect(e, "duplicate column name: ")) {
	            stop(e, call. = FALSE)
	          }
	        }
	      }
	      sql
	    })	
      row["date"]
    })

    if (length(dates) > 0) dt <- dates[length(dates)]

    if (dt > src_version) {
      DBI_Execute(src, 
                  "UPDATE admInfo set db_version = ",
                  "{strftime(dt, '%Y-%m-%d %H:%M:%S')}")
    }
  }
}


checkViews <- function(src, update_sql, response = NULL) {
  # Motus views in database
  motus_views <- c("alltags", "alltagsGPS", "allruns", "allrunsGPS", "allambigs")
  motus_views_str <- stringr::regex(
    paste0("\\b", paste0(motus_views, collapse = "\\b|\\b"), "\\b"), 
    ignore_case = TRUE)
  
  # Any custom views in database?
  db_views <- DBI_Query(
    src, 
    "SELECT name, sql FROM sqlite_master WHERE type = 'view'") %>%
    dplyr::filter(!.data$name %in% motus_views)
  
  # If none, stop here
  if(nrow(db_views) == 0) return()
  
  # Check if any motus views in update_sql
  motus_views_sql <- stringr::regex(
    paste0(paste0("(DROP VIEW IF EXISTS ", motus_views, "\\b)"), collapse = "|"),
    ignore_case = TRUE)
  
  motus_views_update <- stringr::str_extract_all(update_sql, motus_views_sql) %>%
    unlist() %>%
    stringr::str_extract(motus_views_str) %>%
    unique()
  
  # If none, stop here
  if(length(motus_views_update) == 0) return()
  
  # If some are modified, check if custom views affected
  db_views <- db_views %>%
    dplyr::mutate(motus_views = stringr::str_detect(.data$sql, motus_views_str)) %>%
    dplyr::filter(motus_views == TRUE)

  # If yes, inform user
  if(nrow(db_views) > 0) {
    
    sql_name <- file.path(
      dirname(src@dbname), 
      paste0(stringr::str_remove(basename(src@dbname), ".motus"),
             "_custom_views_", Sys.Date(), ".log"))
    
    writeLines(db_views$sql, con = sql_name, sep = "\r\n\r\n\r\n\r\n\r\n")
    
    msg <- paste0(stringr::str_wrap(paste0("This database contains custom views which ",
                  "have to be removed before the update can proceed: \n",
                  paste0(db_views$name, collapse = ", "))), "\n", 
                  "The SQLite commands to create the views have been saved to\n", 
                  sql_name, "\n\n",
                  "Allow motus to delete the views and continue with the update?")
    
    if(is.null(response) && is_testing()) response <- 1
    if(is.null(response)) {
      choice <- utils::menu(choices = c("Yes, delete them", 
                                        "No, I'll deal with it"), 
                            title = msg)
    } else choice <- response
    if(choice == 2) {
      stop("Cannot update local database if conflicting custom views are present",
           call. = FALSE)
    }
    
    # Delete the views before proceeding
    message("Deleting custom views: ", paste0(db_views$name, collapse = ", "))
    for(v in db_views$name) DBI_Execute(src, "DROP VIEW {v}")
  }
}


checkFields <- function(src) {
  
  tbls <- DBI::dbListTables(src)
  tbls <- tbls[tbls %in% sql_fields$table]
  
  for(t in tbls) {
   f <- DBI::dbListFields(src, t) 
   s <- dplyr::filter(sql_fields, table == !!t)
   
   # Check for an add missing columns/fields
   if(any(!s$column %in% f)) {
     miss <- s$sql[!s$column %in% f]
     miss <- glue::glue("ALTER TABLE {t} ADD COLUMN {miss};")
     DBI_ExecuteAll(src, miss)
   }
   if(all(s$extra[[1]] != FALSE)) DBI_ExecuteAll(src, s$extra[[1]])
  }
}