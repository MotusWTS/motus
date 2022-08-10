#' Insert or replace records in data base
#' 
#' Save records from a data frame into a db table, replacing
#' existing records when primary keys collide.
#'
#' @param src database source
#' @param name name of table to insert or replace records into
#' @param df data from which to write data.
#' @param replace boolean that determines whether existing records are replaced
#'   or ignored.
#'
#' @noRd

dbInsertOrReplace <- function(src, name, df, replace = TRUE) {
    if (nrow(df) == 0)  return()

    ## remove fields from df that are not in the database
    ## An alternative would be to add them, but this may best
    ## dealt with elsewhere
    fields <- DBI_Query(src, "PRAGMA table_info({name})")
    df <- df[names(df) %in% fields$name]
    
    refcols <- subset(fields$name, fields$name %in% names(df))

    ## reorder the fields in df to match the table
    df <- df[, subset(fields$name, fields$name %in% names(df))]
    
    tmp <- basename(tempfile("zztmp"))

    ## create a temporary table with the same structure as
    ## the target; don't use the 'temporary' keyword
    ## because this somehow prevents 'drop table' below
    ## from succeeding - it leaves an empty table in the
    ## database.

    DBI_Execute(src, "create table {tmp} as select * from {name} limit 0")

    ## write all records to the temporary table

    DBI::dbWriteTable(src, tmp, df, row.names = FALSE, append = TRUE)

    ## replace/insert records from the temporary table
    ## into the target

    if (replace) {
      DBI_Execute(src, "replace into {name} select * from {tmp}")
    } else {
      DBI_Execute(src, "insert or ignore into {name} select * from {tmp}")
    }

    ## drop the temporary table

    DBI_Execute(src, "drop table {tmp}")
}
