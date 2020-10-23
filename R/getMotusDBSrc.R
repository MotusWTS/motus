#' Get the src_sqlite for a receiver or tag database
#'
#' Receiver database files have names like "SG-1234BBBK06EA.motus" or
#' "Lotek-12345.motus", and project database files have names like
#' "project-52.motus".
#'
#' @param recv receiver serial number
#'
#' @param proj integer motus project number
#' exactly  one of `proj` or `recv` must be specified.
#'
#' @param create Is this a new database?  Default: FALSE. Same semantics as for
#'   `src_sqlite()`'s parameter of the same name:  the DB must already exist
#'   unless you specify `create = TRUE`
#' @param dbDir path to folder with existing receiver databases Default:
#'   `motus_vars$dbDir`, which is set to the current folder by
#'   `getwd()` when this library is loaded.
#'
#' @return a src_sqlite for the receiver; if the receiver is new, this database
#' will be empty, but have the correct schema.
#'
#' @export

getMotusDBSrc = function(recv=NULL, proj=NULL, create = FALSE, dbDir = motus_vars$dbDir) {
    if (missing(recv) + missing(proj) != 1)
        stop("Must specify exactly one of `recv` or `proj`", call. = FALSE)
    name = if(missing(proj)) recv else sprintf("project-%d", proj)
    src = dplyr::src_sqlite(file.path(dbDir, paste0(name, ".motus")), create)
    ensureDBTables(src, recv, proj)
    return(src)
}
