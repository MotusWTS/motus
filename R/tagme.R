#' Download motus tag detections to a database
#'
#' @param projRecv integer. Project code from motus.org, *or* character
#'   scalar receiver serial number
#' @param update logical. Should any new data be downloaded and merged?
#'   Defaults to TRUE unless this is a new database (in which case you must
#'   specify `update = TRUE` explicitly).
#' @param new logical. Is this a new database?  Default: FALSE You have to
#'   specify `new = TRUE` if you want a new local copy of the database to be
#'   created. Otherwise, `tagme()` assumes the database already exists,
#'   and will stop with an error if it cannot find it in the current directory.
#'   This is mainly to prevent inadvertent downloads of large amounts of data
#'   that you already have!
#' @param dir character. Path to the folder where you are storing databases
#'   Defaults to current directory; i.e. `getwd()`.
#' @param countOnly logical. If FALSE, the default, then do requested
#'   database updates. Otherwise, return a count of items that would need to be
#'   transferred in order to update the database.
#' @param forceMeta logical. If TRUE, re-get metadata for tags and receivers,
#'   even if we already have them.
#' @param rename logical. If current SQLite database is of an older version,
#'   automatically rename that database for backup purposes and download the
#'   newest version. If FALSE (default), user is prompted for action.
#' @param skipActivity logical. Skip checking for and downloading `activity`? See
#'   `?activity` for more details
#' @param skipNodes logical. Skip checking for and downloading `nodeData`? See
#'   `?nodeData` for more details
#' @param skipDeprecated logical. Skip fetching list of deprecated batches
#'   stored in `deprecated`. See `?deprecateBatches()` for more details.
#'
#' @examples
#'
#' ## create and open a local tag database for motus project 14 in the
#' ## current directory
#'
#' # t = tagme(14, new=TRUE)
#'
#' ## update and open the local tag database for motus project 14;
#' ## it must already exist and be in the current directory
#'
#' # t = tagme(14, update=TRUE)
#'
#' ## update and open the local tag database for a receiver;
#' ## it must already exist and be in the current directory
#'
#' # t = tagme("SG-1234BBBK4567", update=TRUE)
#'
#' ## open the local tag database for a receiver, without
#' ## updating it
#'
#' # t = tagme("SG-1234BBBK4567")
#'
#' ## open the local tag database for a receiver, but
#' ## tell 'tagme' that it is in a specific directory
#'
#' # t = tagme("SG-1234BBBK4567", dir="Projects/gulls")
#'
#' ## update all existing project and receiver databases in \code{dir}
#' # tagme()
#'
#' @return a dplyr::src_sqlite for the (possibly updated) database, or a list
#' of counts if \code{countOnly==TRUE}
#'
#' @seealso \code{\link{tellme}}, which is a synonym for \code{tagme(..., update=TRUE, countOnly=TRUE)}
#'
#' @export

tagme <- function(projRecv, update = TRUE, new = FALSE, dir = getwd(), 
                  countOnly = FALSE, forceMeta = FALSE, rename = FALSE,
                  skipActivity = FALSE, skipNodes = FALSE, skipDeprecated = FALSE) {
  if (missing(projRecv) && ! new) {
    ## special case: update all existing databases in \code{dir}
    lapply(dir(dir, pattern="\\.motus$"),
           function(f) {
             tagme(projRecv = sub("\\.motus$", "", f), update = TRUE, dir = dir, 
                   countOnly = countOnly, forceMeta = forceMeta)
           }) %>%
      return()
  }
  
  if (length(projRecv) != 1 || (! is.numeric(projRecv) && ! is.character(projRecv)))
    stop("You must specify one integer project ID or character receiver serial number.", call. = FALSE)
  
  if (is.character(projRecv) && grepl("\\.motus$", projRecv, ignore.case=TRUE))
    projRecv = gsub("\\.motus$", projRecv, ignore.case=TRUE)
  
  dbname <- getDBFilename(projRecv, dir)
  have <- file.exists(dbname)
  
  if (! new && ! have)
    stop("Database ", dbname, " does not exist.\n",
         "If you *really* want to create a new database, specify 'new=TRUE'\n",
         "But maybe you just need to specify 'dir=' to tell me where to find it?", 
         call. = FALSE)
  
  if (new && have) {
    warning("Database ", dbname, " already exists, so I'm ignoring the ",
            "'new=TRUE' option", immediate. = TRUE)
    new <- FALSE
  }
  if (new && missing(update)) update = FALSE
  
  if (! have && is.character(projRecv)) {
    deviceID = srvDeviceIDForReceiver(projRecv)[[2]]
    if (! isTRUE(as.integer(deviceID) > 0))
      stop("Either the serial number '", projRecv, 
           "' is not for a receiver registered\n       with motus or ",
           "this receiver has not yet registered any hits", 
           call. = FALSE)
  } else {
    deviceID = NULL
  }
  
  #rv <- dplyr::src_sqlite(dbname, create = new)
  rv <- dbplyr::src_dbi(con = DBI::dbConnect(RSQLite::SQLite(), dbname))
  
  if (update) {
    
    # Check Data Version either:
    # - Stops (based on user input)
    # - Archives old version and creates new database
    # - Passes and proceeds as expected

    if(!new) {
      rv <- checkDataVersion(rv, dbname = dbname, rename = rename)
      # For receivers, if starting fresh, get the device ID again
      if(length(DBI::dbListTables(rv$con)) == 0 && 
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
    
    # Add activity and nodeData
    if(!countOnly) {
      if(!skipActivity) rv <- activity(src = rv, resume = TRUE)
      if(!skipNodes) rv <- nodeData(src = rv, resume = TRUE)
      if(!skipDeprecated) rv <- fetchDeprecated(src = rv)
    }
  }
  
  rv
}
