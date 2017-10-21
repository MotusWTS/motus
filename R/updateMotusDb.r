#' Ensures that the motus sqlite file is up-to-date to support the current version of the package.
#' Relies on the updateMotusDb.sqlite database in /inst/extdata/ to run the SQL on the basis of date
#' To insert new sql commands, simply create a new record in the sqlite file as follow.
#'   date: date at which the sql update record was added (default current timestamp)
#'   sql: sql string to execute (you should minimize the risk of database errors by using IF EXISTS or DROP as appropriate prior to your command)
#'   descr: description of the update, printed for the user during the update process
#' The function adds a new admInfo table in the motus sqlite file that keeps track of the 
#' date at which the last correction was applied. The updateMotusDb function only exectute
#' sql commands added since the last correction.
#'  
#' This function is called from the z.onLoad function which adds a hook to the ensureDBTables function of the motusClient package.
#' addHook("ensureDBTables", updateMotusDb). I.E., the current function will be called each time that a new motus file is opened
#' (and the ensureDBTables function is accessed).
#'
#' @param rv return value
#' @param src sqlite database source
#' @param projRecv parameter provided by the hook function call, when opening a file built by project ID
#' @param deviceID parameter provided by the hook function call, when opening a file built by receiver ID
#' @export
#' @author Denis Lepage \email{dlepage@@bsc-eoc,org}
#'
#' @return rv

updateMotusDb = function(rv, src, projRecv, deviceID) {

  DBI::dbExecute(src$con, "CREATE TABLE IF NOT EXISTS admInfo (key VARCHAR PRIMARY KEY NOT NULL, value VARCHAR)")
  DBI::dbExecute(src$con, "INSERT OR IGNORE INTO admInfo (key,value) VALUES('db_version',date('1970-01-01'))")
  admInfo = DBI::dbGetQuery(src$con, "select value as db_version from admInfo where key = 'db_version' limit 1")

  dt = as.POSIXct(admInfo$db_version)
  src2 = dplyr::src_sqlite(system.file("extdata", "updateMotusDb.sqlite", package = "motus"), create=FALSE)
  updateSql = DBI::dbGetQuery(src2$con, paste("select date, sql, descr from updateDb where date > '", strftime(dt, "%Y-%m-%d %H:%M:%S"), "' ORDER BY date", sep=""))

  if (length(updateSql[,1]) > 0) {
    cat(sprintf("\nupdateMotusDb started (%d rows)", length(updateSql[,1])))
    dates = apply(updateSql, 1, function(row) {
      cat("\n - ", row["descr"], sep="")
      try(DBI::dbExecute(src$con, row["sql"]))
      row["date"]
    })
    if (length(dates) > 0) dt = dates[length(dates)]
    cat("\n\n")
    
    if (dt > as.POSIXct(admInfo$db_version))
      DBI::dbExecute(src$con, paste("UPDATE admInfo set value = '", strftime(dt, "%Y-%m-%d %H:%M:%S"), "' where key = 'db_version'", sep=""))
  }

  return(rv)
}
