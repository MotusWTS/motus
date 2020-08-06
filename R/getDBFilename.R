#' get the full filename for a tag project or receiver database
#'
#' @param projRecv integer scalar project code from motus.org, *or* character
#'   scalar receiver serial number.
#' @param dir character scalar: path to folder where databases are stored
#'   default: \code{getwd()}
#'
#' @return character scalar giving the full path to the database file for
#' the specified tag project or receiver.  Both DB types have file extensions
#' ".motus", and the base filename looks like either "project-X.motus" or
#' "SG-1234BBBK5678.motus" or "Lotek-12345.motus"
#'
#' @examples
#'
#' # get the path to the database for tag project 123
#' getDBFilename(123) 
#'
#' # get the path to the database for receiver SG-1234BBBK5678
#' getDBFilename("SG-1234BBBK5678")
#'
#' # get the path to the database for project 5 in folder '/home/me/mydbs'
#' getDBFilename(5, "/home/me/mydbs") 
#'
#' @seealso \code{\link{tagme}}
#'
#' @noRd

getDBFilename = function(projRecv, dir = getwd()) {
    if (is.numeric(projRecv)) {
        dbName = sprintf("project-%d.motus", projRecv)
    } else {
        dbName = sprintf("%s.motus", projRecv)
    }
    return (file.path(dir, dbName))
}
