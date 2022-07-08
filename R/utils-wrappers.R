
DBI_Execute <- function(src, ...) {
  DBI::dbExecute(src, glue::glue_sql(..., .con = src, .envir = parent.frame()))
}

DBI_Query <- function(src, ...) {
  q <- DBI::dbGetQuery(src, glue::glue_sql(..., .con = src, .envir = parent.frame()))
  if(all(dim(q) <= 1)) q <- q[[1]]
  q
}

DBI_ExecuteAll <- function(src, statement) {
  if(length(statement) == 1) {
    statement <- stringr::str_remove(statement, ";*( )*$") %>%
      stringr::str_split(";") %>%
      unlist()
  } 
  
  purrr::map(statement, ~ DBI::dbExecute(src, .))
}

msg_fmt <- function(...){
  sprintf_transformer <- function(text, envir) {
    m <- regexpr(":.+$", text)
    if (m != -1) {
      format <- substring(regmatches(text, m), 2)
      regmatches(text, m) <- ""
      res <- eval(parse(text = text, keep.source = FALSE), envir)
      do.call(sprintf, list(glue::glue("%{format}"), res))
    } else {
      eval(parse(text = text, keep.source = FALSE), envir)
    }
  }
  
  glue::glue(..., .transformer = sprintf_transformer, .envir = parent.frame())
}