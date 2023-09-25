required_cols <- function(x, req, name = "data") {
  cols <- colnames(x)
  if(any(!req %in% cols)) {
    stop("Required columns/fields missing from '", name, "': ",
         paste0(req[!req %in% cols], collapse = ", "))
  }
}

check_df <- function(df, type = "df_src", extra = "") {
  if(!inherits(df, "data.frame")) {
    stop("'df' must be a data frame", extra, call. = FALSE) 
  }
}

check_df_src <- function(df_src, cols, extra = "") {

  if(inherits(df_src, "SQLiteConnection")) {
    message("'df_src' is a complete motus data base, using 'alltags' view")
    df_src <- dplyr::tbl(df_src, "alltags")
  }
  if(!is.data.frame(df_src) && !dplyr::is.tbl(df_src)) {
    stop("'df_src' must be a data frame, table/view (e.g., alltags), ",
         "or motus SQLite database (see ?sunRiseSet for examples)", 
         extra, 
         call. = FALSE)
  }
  
  required_cols(df_src, req = cols)
  
  dplyr::collect(df_src)
}