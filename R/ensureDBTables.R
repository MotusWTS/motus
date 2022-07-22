#' Ensure database has required tables
#' 
#' If required tables are missing, create them.
#'
#' @param src SQLite connection
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

ensureDBTables <- function(src, projRecv, deviceID, quiet = FALSE) {

  check_src(src)
  
  if (missing(projRecv)) {
    stop("You must specify a project number or receiver serial number for a ",
         "new database", call. = FALSE)
  }
  isRecvDB <- is.character(projRecv)

  ## reasonably large page size; post 2011 hard drives have 4K sectors anyway
  DBI_Execute(src, "pragma page_size=4096") 
  
  tables <- DBI::dbListTables(src)

  # Create and fill 'meta' table
  if (!"meta" %in% tables) makeMetaTable(src, projRecv, deviceID)
  
  # Create all empty tables
  for(t in c("activity", "activityAll", "antDeps", "batches", "batchRuns", 
             "clarified", "deprecated", "filters", "gps", "gpsAll", "hits", 
             "nodeData", "nodeDeps", "projAmbig", "projs", "pulseCounts",
             "recvDeps", "runs", "runsFilters", "species",
             "tagAmbig", "tagDeps", "tagProps", "tags")) {

    if(!t %in% tables && !(t == "pulseCounts" && !isRecvDB)) {
      DBI_ExecuteAll(src, makeTable(t))
    }
  }
  
  # Create tables to fill (either need current values, or values from DB)
  if(!"admInfo" %in% tables) makeAdmInfo(src)
  if(!"projBatch" %in% tables && !isRecvDB) makeProjBatch(src, projRecv)
  if(!"recvs" %in% tables) makeRecvs(src)
  
  
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

makeMetaTable <- function(src, projRecv, deviceID) {

  DBI_Execute(src, makeTable("meta"))
  
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
    
    DBI::dbExecute(src, glue::glue_collapse(
      glue::glue("INSERT INTO meta (key, val)",
                 "values",
                 "('dbType', 'receiver'),",
                 "('recvSerno', '{projRecv}'),",
                 "('recvType', '{type}'),",
                 "('recvModel', '{model}'),",
                 "('deviceID', '{as.integer(deviceID)}')"), sep = "\n"))
    
    
  } else if (is.numeric(projRecv)) {
    DBI::dbExecute(src, glue::glue_collapse(glue::glue("INSERT INTO meta (key, val)", 
                                       "values",
                                       "('dbType', 'tag'),",
                                       "('tagProject', {projRecv})"), sep = "\n"))
  } else {
    stop("projRecv must be an integer motus project ID or a character receiver serial number", call. = FALSE)
  }
}

makeAdmInfo <- function(src) {
  DBI_Execute(src, makeTable("admInfo"))
  DBI_Execute(
    src, 
    "INSERT INTO admInfo (db_version, data_version) ",
    "values ({max(sql_versions$date)}, {motus_vars$dataVersion})")
}

makeProjBatch <- function(src, projRecv) {
  DBI_Execute(src, makeTable("projBatch"))
  DBI_Execute(
    src, 
    "INSERT INTO projBatch 
      SELECT {projRecv} AS tagDepProjectID, t1.batchID, max(t2.hitID)
      FROM batches AS t1
     JOIN hits AS t2 ON t2.batchID=t1.batchID
     GROUP BY t1.batchID
     ORDER BY t1.batchID")
}

makeRecvs <- function(src) {
  DBI_Execute(src, makeTable("recvs"))
  DBI_Execute(src, 
              "INSERT OR IGNORE INTO recvs ",
              "SELECT deviceID, serno FROM recvDeps")
}

