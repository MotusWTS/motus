checkDataVersion <- function(src, dbname, rename = FALSE) {
  
  # Get current version info
  motus_vars$authToken # Prompt for authorization to get dataVersion
  server_version <- motus_vars$dataVersion
  
  if (DBI::dbExistsTable(src$con, "admInfo") && 
      "data_version" %in% DBI::dbListFields(src$con, "admInfo")) {
    local_version <- dplyr::tbl(src$con, "admInfo") %>%
      dplyr::pull(.data$data_version)
  } else local_version <- character()

  # If missing admInfo table OR data_version, assume is version 1
  if(length(local_version) == 0) local_version <- 1

  if(length(DBI::dbListTables(src$con)) > 1 && local_version < server_version) {

    new_name <- stringr::str_replace(src[[1]]@dbname, 
                                     ".motus$", 
                                     paste0("_v", local_version, ".motus"))
    msg <- paste0(
      "motus sqlite file: ", src[[1]]@dbname, "\n",
      "Local data version (v", local_version, ") ",
      "doesn't match the server version (v", server_version, ").\n",
      "Rename current database to ", basename(new_name), " ",
      "and download v", server_version, " data to a new database?")
    
    if(!rename) {
      choice <- utils::menu(choices = c("Yes", "No"), title = msg)
      if(choice == 2) {
        stop("Cannot update local database if does not match server version",
             call. = FALSE)
      }
    }

    n <- src[[1]]@dbname
    
    message("DATABASE UPDATE (data version 1 -> 2)")
    message(" - Archiving ", basename(n), " (v", local_version, ") to ", 
            basename(new_name))
    
    orig_md5sum <- tools::md5sum(n)

    if(!file.exists(new_name)) {

      # First try renaming
      DBI::dbDisconnect(src$con)
      rm(src)
      gc()
      t <- try(file.rename(from = n, to = new_name), silent = TRUE)
      
      # If renaming succeeds, create new database
      if(class(t) != "try-error") {
        src <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), n))
        
      } else {  # If renaming fails, then try copying
        message("    File rename failed (common on Windows), copying file to archive instead (this may take longer)")
      
        if(file.size(n) > 1073741824 && !rename) {
          t <- paste0("This is a large database (> 1 gig) so archiving may take a while and shouldn't be interrupted.\n",
                      "Alternatively, a faster option is to manually archive your project by closing R and renaming your database file to '", 
                      basename(new_name), 
                      "'.\nThen restart the tagme() function with 'new = TRUE' and 'update = TRUE'.\n",
                      "Are you ready to proceed?")
          choice <- utils::menu(choices = c("Yes, proceed with the archiving", "No, I'll do it myself"), 
                                title = t)
          if(choice == 2) {
            stop("No changes made", call. = FALSE)
          }
        }
        
        t <- try(file.copy(from = n, to = new_name), silent = TRUE)
        if(class(t) == "try-error") stop("Unable to archive database", 
                                         call. = FALSE)
      }
    } else {
      stop(new_name, " already exists", call. = FALSE)
    }

    # Double check that archiving worked as expected
    temp_db <- try(
      DBI::dbConnect(RSQLite::SQLite(), dbname = new_name), 
      silent = TRUE)
    if(class(temp_db) == "try-error" || 
       length(DBI::dbListTables(temp_db)) == 0 || 
       orig_md5sum != tools::md5sum(new_name)) {
      stop("Database did not archive properly", call. = FALSE)
    } else {
      DBI::dbDisconnect(temp_db)
    }

    # Clear current database
    message(" - Preparing database for v", server_version, " data")
    src <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), n))
    
    if(length(DBI::dbListTables(src$con)) > 0) {
      DBI::dbExecute(src$con, "DROP VIEW allambigs")
      DBI::dbExecute(src$con, "DROP VIEW alltags")
      
      sapply(DBI::dbListTables(src$con), 
             FUN = function(x) DBI::dbRemoveTable(src$con, x))
    
      if(length(DBI::dbListTables(src$con)) > 0) {
        stop("Unable to prepare new database", .call = FALSE)
      }
    }
    
    message(" - Downloading new data (v", server_version, ") to ", basename(n))
  }
  
  src
}