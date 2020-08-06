#' Save records from a data frame into a db table, replacing
#' existing records when primary keys collide.
#'
#' Seems like an obvious missing piece of the DBI.  Ideally,
#' dbWriteTable would have a boolean 'replace' argument that served
#' the same purpose; i.e. record-wise overwrite, rather than
#' table-wise.
#'
#' @param con DBI database connection
#' @param name name of table to insert or replace records into
#' @param df data from which to write data.
#' @param replace boolean that determines whether existing records are replaced
#'   or ignored.
#'
#' @return no return value
#'
#' @noRd

dbInsertOrReplace = function(con, name, df, replace=TRUE) {
    if (nrow(df) == 0)
        return()

    sql = function(...) DBI::dbExecute(con, sprintf(...))
    query = function(...) DBI::dbGetQuery(con, sprintf(...))

    ## remove fields from df that are not in the database
    ## An alternative would be to add them, but this may best
    ## dealt with elsewhere

    fields = query("PRAGMA table_info(%s)", name)
    df = df[names(df) %in% fields$name]
    
    refcols = subset(fields$name, fields$name %in% names(df))

    ## reorder the fields in df to match the table
    df = df[, subset(fields$name, fields$name %in% names(df))]
    
    tmp = basename(tempfile("zztmp"))

    ## create a temporary table with the same structure as
    ## the target; don't use the 'temporary' keyword
    ## because this somehow prevents 'drop table' below
    ## from succeeding - it leaves an empty table in the
    ## database.

    sql("create table %s as select * from %s limit 0", tmp, name)

    ## write all records to the temporary table

    DBI::dbWriteTable(con, tmp, df, row.names=FALSE, append=TRUE)

    ## replace/insert records from the temporary table
    ## into the target

    if (replace) sql("replace into %s select * from %s", name, tmp)
    else sql("insert or ignore into %s select * from %s", name, tmp)

    ## drop the temporary table

    sql("drop table %s", tmp)
}
