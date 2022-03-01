#' Ensure database has required tables
#' 
#' If required tables are missing, create them.
#'
#' @param src dplyr sqlite src, as returned by `dplyr::src_sqlite()`
#' @param projRecv integer scalar motus project ID number *or* character scalar
#'   receiver serial number; must be specified if `src` does not already
#'   contain a table named `meta`.
#' @param deviceID integer scalar motus deviceID; must be specified when this is
#'   a new receiver database.
#'   
#' @return returns a dplyr::tbl representing the alltags virtual table which is
#'   created in `src`.
#' 
#' @noRd

ensureDBTables = function(src, projRecv, deviceID, quiet = FALSE) {
  if (!inherits(src, "src_sql")) stop("src is not a dplyr::src_sql object", call. = FALSE)
  con <- src$con
  if (!inherits(con, "SQLiteConnection")) stop("src is not open or is corrupt; underlying db connection invalid", call. = FALSE)
  
  if (missing(projRecv)) {
    stop("You must specify a project number or receiver serial number for a new database", 
         call. = FALSE)
  }
  isRecvDB <- is.character(projRecv)

  ## reasonably large page size; post 2011 hard drives have 4K sectors anyway
  DBI::dbExecute(con, "pragma page_size=4096") 
  
  tables <- dplyr::src_tbls(src)

  # Create and fill 'meta' table
  if (!"meta" %in% tables) makeMetaTable(con, projRecv, deviceID)
  
  # Create all empty tables
  for(t in c("activity", "activityAll", "antDeps", "batches", "batchRuns", 
             "clarified", "deprecated", "filters", "gps", "gpsAll", "hits", 
             "nodeData", "nodeDeps", "projAmbig", "projs", "pulseCounts",
             "recvDeps", "runs", "runsFilters", "species",
             "tagAmbig", "tagDeps", "tagProps", "tags")) {

    if(!t %in% tables && !(t == "pulseCounts" && !isRecvDB)) {
      lapply(makeTable(t), dbExecuteAll, conn = con)
    }
  }
  
  # Create tables to fill (either need current values, or values from DB)
  if(!"admInfo" %in% tables) makeAdmInfo(con)
  if(!"projBatch" %in% tables && !isRecvDB) makeProjBatch(con, projRecv)
  if(!"recvs" %in% tables) makeRecvs(con)
  
  
  updateMotusDb(src, quiet = quiet)
  makeAllambigsView(src)
  makeAlltagsView(src)
  makeAlltagsGPSView(src)
  makeAllrunsView(src)
  makeAllrunsGPSView(src)
  src
}

makeTable <- function(name) {
  dplyr::filter(sql_tables, .data$table == name) %>%
    dplyr::pull(.data$sql) %>%
    unlist()
}

makeMetaTable <- function(con, projRecv, deviceID) {
  sapply(makeTable("meta"), DBI::dbExecute, conn = con)
  
  if (is.character(projRecv))  {  # If Receiver
    if (missing(deviceID) || ! isTRUE(is.numeric(deviceID))) {
      stop("must specify deviceID for new receiver database", call. = FALSE)
    }
    type <- tolower(stringr::str_remove(projRecv, "-(.)*$"))
    
    if (type == "sg") {
      type <- "SENSORGNOME"
      model <- substring(projRecv, 8, 11)
    } else if(type == "lotek") {
      type <- "Lotek"
      model <- getLotekModel(projRecv)
    } else if(type == "ctt") {
      type <- "CTT"
      n <- nchar(projRecv)
      if(n == 15 + 4) {
        model <- "V1"
      } else if(n == 12 + 4) {
        model <- "V2"
      } else stop("Unexpected model for CTT receivers: ", projRecv, call. = FALSE)
    } else {
      stop("Unexpected receiver type: ", type, call. = FALSE)
    }
    
    DBI::dbExecute(con, glue::glue_collapse(
      glue::glue("INSERT INTO meta (key, val)",
                 "values",
                 "('dbType', 'receiver'),",
                 "('recvSerno', '{projRecv}'),",
                 "('recvType', '{type}'),",
                 "('recvModel', '{model}'),",
                 "('deviceID', '{as.integer(deviceID)}')"), sep = "\n"))
    
    
  } else if (is.numeric(projRecv)) {
    DBI::dbExecute(con, glue::glue_collapse(glue::glue("INSERT INTO meta (key, val)", 
                                       "values",
                                       "('dbType', 'tag'),",
                                       "('tagProject', {projRecv})"), sep = "\n"))
  } else {
    stop("projRecv must be an integer motus project ID or a character receiver serial number", call. = FALSE)
  }
}

makeAdmInfo <- function(con) {
  sapply(makeTable("admInfo"), DBI::dbExecute, conn = con)
  DBI::dbExecute(con, 
                 glue::glue("INSERT INTO admInfo (db_version, data_version) 
                             values ('1980-01-01', {motus_vars$dataVersion});"))
}

makeProjBatch <- function(con, projRecv) {
  sapply(makeTable("projBatch"), DBI::dbExecute, conn = con)
  DBI::dbExecute(con, glue::glue(
    "INSERT INTO projBatch 
      SELECT {projRecv} AS tagDepProjectID, t1.batchID, max(t2.hitID)
      FROM batches AS t1
     JOIN hits AS t2 ON t2.batchID=t1.batchID
     GROUP BY t1.batchID
     ORDER BY t1.batchID"))
}

makeRecvs <- function(con) {
  sapply(makeTable("recvs"), DBI::dbExecute, conn = con)
  DBI::dbExecute(con, "INSERT OR IGNORE INTO recvs 
                       SELECT deviceID, serno FROM recvDeps")
}

dbExecuteAll <- function(conn, statement) {
  if(length(statement) == 1) {
    statement <- stringr::str_remove(statement, ";*( )*$") %>%
      stringr::str_split(";") %>%
      unlist()
  } 

  purrr::map(statement, ~ DBI::dbExecute(conn, .))
}

