#' Download motus tag detections to a database
#' 
#' This is the main motus function for accessing and updating your data. This
#' function downloads motus data to a local SQLite data base in the name of 
#' `project-XXX.motus` or `RECIVER_NAME.motus`. If you are having trouble with
#' a particular data base timing out on downloads, see `srvTimeout()` for 
#' options.
#'
#' @param update Logical. Download and merge new data (Default `TRUE`)?
#' @param new Logical. Create a new database (Default `FALSE`)? Specify 
#'   `new = TRUE` to create a new local copy of the database to be downloaded. 
#'   Otherwise, it assumes the database already exists, and will stop with an
#'   error if it cannot find it in the current directory. This is mainly to
#'   prevent inadvertent downloads of large amounts of data that you already
#'   have!
#' @param dir Character. Path to the folder where you are storing databases
#'   IF `NULL` (default), uses current working directory.
#' @param countOnly Logical. If `TRUE`, return only a count of items that would
#'   need to be downloaded in order to update the database (Default `FALSE`).
#' @param forceMeta Logical. If `TRUE`, re-download metadata for tags and
#'   receivers, even if we already have them.
#' @param rename Logical. If current SQLite database is of an older data
#'   version, automatically rename that database for backup purposes and
#'   download the newest version. If `FALSE` (default), user is prompted for
#'   action.
#' @param skipActivity Logical. Skip checking for and downloading `activity`?
#'   See `?activity` for more details
#' @param skipNodes Logical. Skip checking for and downloading `nodeData`? See
#'   `?nodeData` for more details
#' @param skipDeprecated Logical. Skip fetching list of deprecated batches
#'   stored in `deprecated`. See `?deprecateBatches()` for more details.
#'
#' @inheritParams args
#'
#' @examples
#' 
#' \dontrun{
#'
#' # Create and update a local tag database for motus project 14 in the
#' # current directory
#'
#' t <- tagme(14, new = TRUE)
#'
#' # Update and open the local tag database for motus project 14;
#' # it must already exist and be in the current directory
#'
#' t <- tagme(14)
#'
#' # Update and open the local tag database for a receiver;
#' # it must already exist and be in the current directory
#'
#' t <- tagme("SG-1234BBBK4567")
#'
#' # Open the local tag database for a receiver, without
#' # updating it
#'
#' t <- tagme("SG-1234BBBK4567", update = FALSE)
#'
#' # Open the local tag database for a receiver, but
#' # tell 'tagme' that it is in a specific directory
#'
#' t <- tagme("SG-1234BBBK4567", dir = "Projects/gulls")
#'
#' # Update all existing project and receiver databases in the current working
#' # directory
#' 
#' tagme()
#' }
#'
#' @return a SQLite Connection for the (possibly updated) database, or a data 
#' frame of counts if `countOnly = TRUE`.
#'
#' @seealso `tellme()`, which is a synonym for 
#' `tagme(..., countOnly = TRUE)`
#'
#' @export

tagme <- function(projRecv, update = TRUE, new = FALSE, dir = getwd(), 
                  countOnly = FALSE, forceMeta = FALSE, rename = FALSE,
                  skipActivity = FALSE, skipNodes = FALSE, skipDeprecated = FALSE) {
  
  if(is.null(dir)) dir <- "."
  
  # Update all existing databases in `dir`
  if (missing(projRecv) && !new) {
    dbs <- dir(dir, pattern = "\\.motus$") %>%
      stringr::str_remove("\\.motus$")
    lapply(
      dbs,
      function(f) {
        if(stringr::str_detect(f, "project-")) f <- as.numeric(stringr::str_remove(f, "project-"))
        tagme(projRecv = f, 
              update = TRUE, dir = dir, 
              countOnly = countOnly, forceMeta = forceMeta, 
              skipActivity = skipActivity,
              skipNodes = skipNodes, skipDeprecated = skipDeprecated)
      })
    
    return(invisible())
  }
  
  if (length(projRecv) != 1 || (! is.numeric(projRecv) && ! is.character(projRecv))) {
    stop("You must specify one integer project ID or character receiver ",
         "serial number.", call. = FALSE)
  }
  
  if (is.character(projRecv) && grepl("\\.motus$", projRecv, ignore.case = TRUE)) {
    projRecv <- gsub("\\.motus$", projRecv, ignore.case = TRUE)
  }
  
  dbname <- getDBFilename(projRecv, dir)
  have <- file.exists(dbname)

  if (!new && !have) {
    stop("Database ", dbname, " does not exist.\n",
         "If you *really* want to create a new database, specify 'new = TRUE'\n",
         "But maybe you just need to specify 'dir = ' to tell me where to find it?", 
         call. = FALSE)
  }
  
  if (new && have) {
    warning("Database ", dbname, " already exists, so I'm ignoring the ",
            "'new = TRUE' option", immediate. = TRUE, call. = FALSE)
    new <- FALSE
  }
  
  if (!have && is.character(projRecv)) {
    deviceID <- srvDeviceIDForReceiver(projRecv)[[2]]
    if (!isTRUE(as.integer(deviceID) > 0)) {
      stop("Either the serial number '", projRecv, 
           "' is not for a receiver registered\n       with motus or ",
           "this receiver has not yet registered any hits", 
           call. = FALSE)
    }
  } else {
    deviceID <- NULL
  }
  
  rv <- DBI::dbConnect(RSQLite::SQLite(), dbname)
  
  if (update) {
    
    # Check Data Version either:
    # - Stops (based on user input)
    # - Archives old version and creates new database
    # - Passes and proceeds as expected

    if(!new) {
      rv <- checkDataVersion(rv, dbname = dbname, rename = rename)
      # For receivers, if starting fresh, get the device ID again
      if(length(DBI::dbListTables(rv)) == 0 && 
         is.null(deviceID) && !is_proj(projRecv)) {
        deviceID <- srvDeviceIDForReceiver(projRecv)[[2]]
      }
    } else {
      # Prompt for authorization to update dataVersion prior to filling tables
      motus_vars$authToken 
    }
    
    
    # Ensure correct DBtables, but only if update = TRUE
    ensureDBTables(rv, projRecv, deviceID, quiet = new)
    
    # Update database
    rv <- motusUpdateDB(projRecv, rv, countOnly, forceMeta)
    
    # Add extra data - activity, nodeData, deprecated
    if(!countOnly) {
      
      # Check if nodeData required - For receivers only
      if(!is.null(deviceID) && !skipNodes && 
         stringr::str_detect(projRecv, "^CTT-", negate = TRUE)) {
        skipNodes <- TRUE
        message("Reciever is not a SensorStation, skipping node data download")
      }
      
      if(!skipActivity) rv <- activity(src = rv, resume = TRUE)
      if(!skipNodes) rv <- nodeData(src = rv, resume = TRUE)
      if(!skipDeprecated) rv <- fetchDeprecated(src = rv)
    }
  }
  
  rv
}
