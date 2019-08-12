#' Verifies the version of the package against the admInfo table of a motus file. Those should match
#' if the updateMotusDb function has been properly loaded by the tagme function.
#'
#' @param src motus sqlite database source
#' @export
#' @author Denis Lepage \email{dlepage@@bsc-eoc.org}
#'

checkVersion <- function(src) {

  # Get current version info
  current_version <- max(sql_versions$date)
  message("Motus package database version: ", current_version)

  # Get current database info
  message("Your motus sqlite file: ", src[[1]]@dbname)
  
  # If database has admin info table
  if (dplyr::db_has_table(src$con, "admInfo")) {
    df <- DBI::dbGetQuery(src$con, "select value as date from admInfo where key = 'db_version' limit 1")
    df$date <- as.POSIXct(df$date, tz = "UTC")
    message("Your motus sqlite file version: ", df$date)
  
    if (df$date != current_version) {
      message("Your motus sqlite file version does not match the package. ",
              "Please refer to the Motus R Book (troubleshooting chapter).")
    }	else {
      message("Your motus sqlite file is up-to-date with the package.")
    }
  } else {
    message("The admInfo table has not yet been created in your motus sqlite ", 
            "file. Please refer to the Motus R Book (troubleshooting chapter).")
  }
}
