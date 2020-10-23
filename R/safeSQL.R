#' Return a function that safely performs sql queries on a connection.
#'
#' This uses the `params` parameter for [DBI::dbGetQuery()]
#' and [DBI::dbExecute()] (for RSQLite and ":" parameters)
#' or dbQuoteStrings (for MySQL or RSQLite "%" parameters).  It should
#' prevent e.g. SQL injection attacks.
#'
#' @param con RSQLite connection to database, as returned by
#'     dbConnect(SQLite(), ...), or character scalar giving path
#'     to SQLite database, or MySQLConnection, or [dplyr::src()]
#'
#' @param busyTimeout how many total seconds to wait while retrying a
#'     locked database.  Default: 300 (5 minutes).  Uses \code{pragma busy_timeout}
#'     to allow for inter-process DB locking.  Only implemented for
#'     SQLite connections, as it appears unnecessary for MySQL
#'     connections.
#'
#' @return a function, S with class "safeSQL" taking two or more
#'     parameters:
#' \itemize{
#'     \item \code{query} sqlite query with parameter handling indicated by:
#'     \itemize{
#'        \item words beginning with ":", which does parameter binding for RSQLite,
#'        \item \bold{or} sprintf-style formatting codes (e.g. "\%d") which does parameter substitution for RSQLite or MySQL
#'     }
#'     \item \code{...} list of named (for ":" binding) or unnamed
#'     (for "%" substitution) items specifying values for parameters in
#'     query.  For ":" binding, all items must be named and have the same
#'     length.  For "%" substitution, all items must be unnamed scalars.
#' }
#'
#' For RSQLite, these items are passed to \code{data.frame}, along with the
#' parameter \code{stringsAsFactors=FALSE}.
#' \itemize{
#' \item \emph{":"-binding example; SQLite only}:
#' \code{
#' S("insert into contacts values(:address, :phone)", address=c("123 West Blvd, Truro, NS", "5 East St., Digby, NS"), phone=c("902-555-1234", "902-555-6789"))
#' }
#' \item \emph{"%"-substitution example; SQLite or MySQL}:
#' \code{
#' S("insert into contacts values(\"%s\", \"%s\")", "123 West Blvd, Truro, NS", "902-555-1234")
#' S("insert into contacts values(\"%s\", \"%s\")", "5 East St., Digby, NS", "902-555-6789")
#' }
#' }
#'
#' \item \code{.CLOSE} boolean scalar; if TRUE, close the underlying
#' database connection, disabling further use of this function.
#'
#' \item \code{.QUOTE} boolean scalar (only for RMySQL connections); if TRUE, the
#' default, quote string parameters using [dbQuoteString()].  Any parameter
#' wrapped in [DBI::SQL()] will not be quoted.  The only reason to use
#' \code{.QUOTE=FALSE} is for a query where you know all parameters must not be
#' quoted, and don't want to clutter your code with multiple [DBI::SQL()].
#' A table name used as a parameter to a query should not be quoted, so for example,
#' \code{
#' s = safeSQL(dbConnect(MySQL(), 'motus'));
#' tableName = "tags"
#' columnName = "fullID"
#' columnValue = "Mytags#123:4.7@166.38"
#' s("select * from %s where %s=%s", DBI::SQL(tableName), DBI::SQL(columnName), columnValue)
#' }
#' would select all rows from the \code{tags} table where \code{fullID="Mytags#123:4.7@166.38"}
#' Without using [DBI::SQL()], the resulting query would be the incorrect:
#' \code{select * from 'tags' where 'fullID' = 'Mytags#123:4.7@166.38'}
#' }
#'
#' @note for convenience, access is provided to some safeSQL internals, via the
#' "$" method for class \code{safeSQL}
#' \itemize{
#' \item \code{$con} the underlying db connection
#' \item \code{$db} the underlying database filename
#' }
#'
#' For MySQL, only one line of an insert can be provided per call; i.e. there is
#' no SendPreparedQuery method to allow binding a data.frame's data to a prepared
#' query.  Moreover, character parameters are quoted using [DBI::dbQuoteString()]
#' unless the parameter is wrapped in [DBI::SQL()], or if you
#' specify \code{.QUOTE=FALSE}
#'
#' safeSQL is meant for multi-process access of a DB with small, fast
#' queries; this is the case for the server.sqlite database that holds
#' job information.  The longer accesses required by e.g. the tag
#' finder are handled by locking the receiver DB via lockSymbol().
#'
#' For both MySQL and SQLite connections, queries that fail due
#' to deadlock-prevention by the database are retried after a random wait
#' of 0 to 10 seconds.
#'
#' @noRd

safeSQL = function(con, busyTimeout = 300) {
    if (inherits(con, "safeSQL"))
        return(con)
    if (inherits(con, "src"))
        con = con$con
    if (is.character(con))
        con = DBI::dbConnect(RSQLite::SQLite(), con)
    isSQLite = inherits(con, "SQLiteConnection")
    if (isSQLite) {

        ########## RSQLite ##########

        DBI::dbGetQuery(con, sprintf("pragma busy_timeout=%d", round(busyTimeout * 1000)))
        structure(
            function(query, ..., .CLOSE=FALSE, .QUOTE=FALSE) {
                if (.CLOSE) {
                    DBI::dbDisconnect(con)
                    return(con <<- NULL)
                }
                queryFun = if(grepl("(?i)^[[:space:]]*select|pragma|with", query, perl=TRUE)) DBI::dbGetQuery else DBI::dbExecute
                repeat {
                    tryCatch({
                        a = list(...)
                        if (length(a) > 0) {
                            if (!is.null(names(a))) {
                                return(queryFun(con, query, params=a))
                            } else {
                                if (.QUOTE) {
                                    ## there are some parameters to the query, so escape those which are strings
                                    a = c(query, lapply(a, function(x) if (is.character(x)) DBI::dbQuoteString(con=con, x) else x ))
                                } else {
                                    a = c(query, a)
                                }
                                q = do.call(sprintf, a)
                                return(queryFun(con, q))
                            }
                        } else {
                            return(queryFun(con, query))
                        }
                    },
                    error = function(e) {
                        if (! grepl("database is locked", as.character(e)))
                            stop(e, call. = FALSE) ## re-throw if the error isn't due to a locked database
                    })
                    ## failed due to locked database; wait a while and retry
                    Sys.sleep(10 * stats::runif(1))
                }
            },
            class = "safeSQL"
        )
    } else {

        ########## MySQL ########
        DBI::dbGetQuery(con, "set character set 'utf8'")
        structure(
            function(..., .CLOSE=FALSE, .QUOTE=TRUE) {
                if (.CLOSE) {
                    DBI::dbDisconnect(con)
                    return(con <<- NULL)
                }
                a = list(...)
                if (length(a) > 1 && .QUOTE) {
                    ## there are some parameters to the query, so escape those which are strings
                    a = c(a[[1]], lapply(a[-1], function(x) if (is.character(x)) DBI::dbQuoteString(con=con, x) else x ))
                }
                q = do.call(sprintf, a)
                Encoding(q) = "UTF-8"
                queryFun = if(grepl("(?i)^[[:space:]]*select", q, perl=TRUE)) DBI::dbGetQuery else DBI::dbExecute
                repeat {
                    tryCatch(
                        return(queryFun(con, q)),
                        error = function(e) {
                            if (! grepl("Deadlock.*try restarting transaction", as.character(e), perl=TRUE))
                                stop(e, call. = FALSE) ## re-throw if error isn't due to a locked database
                        })
                    ## failed due to locked database; wait a while and retry
                    Sys.sleep(10 * stats::runif(1))
                }
            },
            class = "safeSQL"
        )
    }
}

#' safeSQL method to provide read access to some internals
#'
#' @param x object
#' @param name item name; must be one of 'db' or 'con'
#'
#' @return either the database filename, or the db connection
#'
#' @noRd

`$.safeSQL` = function(x, name) {
    con = environment(x)$con
    switch(substitute(name),
           db = if(inherits(con, "MySQLConnection")) con@db else con@dbname,
           con = con,
           NULL
           )
}

#' safeSQL method for printing
#' @param x safeSQL object
#' @param ... For print() compatibility
#' @return invisible(NULL)
#' @noRd

print.safeSQL = function(x, ...) {
    message("Safe SQL object attached to ", x$db, "\nDo ?safeSQL for more details.")
}
