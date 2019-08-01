checkDataVersion <- function(src, dbname, rename = FALSE) {
  
  # Get current version info
  motus_vars$authToken # Prompt for authorization to get dataVersion
  server_version <- motus_vars$dataVersion
  
  if (dplyr::db_has_table(src$con, "admInfo")) {
    local_version <- dplyr::tbl(src$con, "admInfo") %>%
      dplyr::filter(key == "data_version") %>%
      dplyr::pull(value)
  } else local_version <- character()
  
  # If missing admInfo table OR data_version, assume is version 1
  if(length(local_version) == 0) local_version <- 1

  if(local_version < server_version) {

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
    if(!file.exists(new_name)) {
      file.rename(from = n, to = new_name)
    } else {
      stop(new_name, " already exists", call. = FALSE)
    }
    src <- dplyr::src_sqlite(dbname, create = TRUE)
  }
  
  src
}