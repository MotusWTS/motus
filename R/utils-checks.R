check_src <- function(src) {
  if (!inherits(src, "SQLiteConnection")) {
    stop("src must be a SQLite database connection created with `tagme()`\n",
         "or `DBI::dbConnect()", call. = FALSE)
  }
}