required_cols <- function(x, req, name = "data") {
  cols <- colnames(x)
  if(any(!req %in% cols)) {
    stop("Required columns/fields missing from '", name, "': ",
         paste0(req[!req %in% cols], collapse = ", "))
  }
  x
}

check_df <- function(df, type = "df_src", extra = "") {
  if(!inherits(df, "data.frame")) {
    stop("'df' must be a data frame", extra, call. = FALSE) 
  }
}

check_df_src <- function(df_src, cols, view = "alltags", collect = TRUE, extra = "") {

  fun <- sys.call(-1)
  if(!is.null(fun)) fun <- as.list(fun)[[1]] else fun <- "tagme"
  
  if(inherits(df_src, "SQLiteConnection")) {
    message("'df_src' is a complete motus data base, using '", view, "' view")
    df_src <- dplyr::tbl(df_src, view)
  }
  if(!is.data.frame(df_src) && !dplyr::is.tbl(df_src)) {
    stop("'df_src' must be a data frame, a table/view (e.g., ", view, "), ",
         "or a motus\nSQLite database (see ?", fun, " for examples)", 
         extra, 
         call. = FALSE)
  }
  
  if(collect) df_src <- dplyr::collect(df_src)
  
  required_cols(df_src, req = cols)
}