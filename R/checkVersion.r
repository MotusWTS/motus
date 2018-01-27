#' Verifies the version of the package against the admInfo table of a motus file. Those should match
#' if the updateMotusDb function has been properly loaded by the tagme function.
#'
#' @param src motus sqlite database source
#' @export
#' @author Denis Lepage \email{dlepage@@bsc-eoc.org}
#'

checkVersion = function(src) {

  src2 = dplyr::src_sqlite(system.file("extdata", "updateMotusDb.sqlite", package = "motus"), create=FALSE)
  df2 = DBI::dbGetQuery(src2$con, "select max(date) as date from updateDb")
  cat(paste("Motus package database version: ", df2$date, "\n", sep=""))

  cat(paste("Motus sqlite file: ", src[[1]]@dbname, "\n", sep=""))
  
  master = DBI::dbGetQuery(src$con, "SELECT * FROM sqlite_master WHERE name ='admInfo' and type='table'")
  if (length(master[,1]) > 0) {
	df = DBI::dbGetQuery(src$con, "select value as date from admInfo where key = 'db_version' limit 1")
	cat(paste("Your motus sqlite file version: ", df$date, "\n", sep=""))
	if (df2$date != df$date) 
		cat("Your motus sqlite file version does not match the package. Please refer to the Motus R Book (troubleshooting chapter).\n")
	else 
		cat("Your motus sqlite file is up-to-date with the package.\n")
  } else {
	cat("The admInfo table has not yet been created in your motus sqlite file. Please refer to the Motus R Book (troubleshooting chapter).\n")
  }
}
