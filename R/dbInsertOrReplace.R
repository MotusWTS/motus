#' Save records from a data frame into a db table, replacing
#' existing records when primary keys collide.
#'
#' Seems like an obvious missing piece of the DBI.  Ideally,
#' dbWriteTable would have a boolean 'replace' argument that served
#' the same purpose; i.e. record-wise overwrite, rather than
#' table-wise.
#'
#' @param con DBI database connection
#'
#' @param name name of table to insert or replace records into
#'
#' @param df data from from which to write data.
#'
#' @return no return value
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

dbInsertOrReplace = function(con, name, df) {
    if (nrow(df) == 0)
        return()

    sql = function(...) dbGetQuery(con, sprintf(...))

    tmp = basename(tempfile("zztmp"))

    ## create a temporary table with the same structure as
    ## the target; don't use the 'temporary' keyword
    ## because this somehow prevents 'drop table' below
    ## from succeeding - it leaves an empty table in the
    ## database.

    sql("create table %s as select * from %s limit 0", tmp, name)

    ## write all records to the temporary table

    dbWriteTable(con, tmp, df, row.names=FALSE, append=TRUE)

    ## replace/insert records from the temporary table
    ## into the target

    sql("replace into %s select * from %s", name, tmp)

    ## drop the temporary table

    sql("drop table %s", tmp)
}
