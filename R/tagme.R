#' update a motus tag detection database
#'
#' @param projRecv integer scalar project code from motus.org, *or*
#' character scalar receiver serial number
#'
#' @param update boolean scalar: should any new data be downloaded and merged?
#' default: TRUE, unless this is a new database (in which case you must
#' specify \code{update=TRUE} explicitly).
#'
#' @param new logical scalar: is this a new database?  Default: FALSE
#' You have to specify \code{new=TRUE} if you want a new local copy of the
#' database to be created.  Otherwise, \code{tagme()} assumes the database
#' already exists, and will stop with an error if it cannot find it
#' in the current directory.  This is mainly to prevent inadvertent
#' downloads of large amounts of data that you already have!
#'
#' @param dir: path to the folder where you are storing databases
#' Default: the current directory; i.e. \code{getwd()}
#'
#' @param countOnly logical scalar: if FALSE, the default, then do
#'     requested database updates.  Otherwise, return a count of items
#'     that would need to be transferred in order to update the
#'     database.
#'
#' @param forceMeta logical scalar: if true, re-get metadata for tags and
#' receivers, even if we already have them.
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
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

tagme = function(projRecv, update=TRUE, new=FALSE, dir=getwd(), countOnly=FALSE, forceMeta=FALSE) {
    if (missing(projRecv) && ! new) {
        ## special case: update all existing databases in \code{dir}
        return(lapply(dir(dir, pattern="\\.motus$"),
                      function(f) {
                          tagme(projRecv=sub("\\.motus$", "", f), update=TRUE, dir=dir, countOnly=countOnly, forceMeta=forceMeta)
                      }))
    }
    if (length(projRecv) != 1 || (! is.numeric(projRecv) && ! is.character(projRecv)))
        stop("You must specify an integer project ID or a character receiver serial number.")
    if (is.character(projRecv) && grepl("\\.motus$", projRecv, ignore.case=TRUE))
        projRecv = gsub("\\.motus$", projRecv, ignore.case=TRUE)
    dbname = getDBFilename(projRecv, dir)
    have = file.exists(dbname)
    if (! new && ! have)
        stop("Database ", dbname, " does not exist.\n",
             "If you *really* want to create a new database, specify 'new=TRUE'\n",
             "But maybe you just need to specify 'dir=' to tell me where to find it?"
             )
    if (new && have)
        warning("Database ", dbname, " already exists, so I'm ignoring the 'new=TRUE' option")
    if (new && missing(update))
        update = FALSE
    if (! have && is.character(projRecv)) {
        deviceID = srvDeviceIDForReceiver(projRecv)[[2]]
        if (! isTRUE(as.integer(deviceID) > 0))
            stop("Either the serial number '", projRecv, "' is not for a receiver registered with motus\nor you don't have permission to access it")
    } else {
        deviceID = NULL
    }

    rv = dplyr::src_sqlite(dbname, create=new)

    ensureDBTables(rv, projRecv, deviceID)

    if (update)
        rv = motusUpdateDB(projRecv, rv, countOnly, forceMeta)

    return(rv)
}
