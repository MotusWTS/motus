#' Write to the local database the probabilities associated with runs for a filter
#'
#' @param df Data frame. Containing `runID`, `motusTagID` and probability values
#'   to save in the local database
#' @param overwrite Logical. When `TRUE` ensures that existing records matching
#'   the same `filterName` and `runID` get replaced
#' @param delete Logical. When TRUE, removes all existing filter records
#'   associated with the `filterName` and re-inserts the ones contained in the
#'   dataframe. This option should be used if the dataframe provided contains
#'   the entire set of filters you want to save.
#'
#' @inheritParams args
#'
#' @return database connection refering to the filter created
#'
#' @export

writeRunsFilter <- function(src, filterName, motusProjID = NA, df, 
                            overwrite = TRUE, delete = FALSE) {

  # Check for probability column
  if(!all(c("runID", "motusTagID","probability") %in% names(df))) {
    stop("'df' must have at least columns 'runID', 'motusTagID', and ",
         "'probability'", call. = FALSE)
  }
  
  # determines the filterID
  id <- createRunsFilter(src, filterName, motusProjID, update = FALSE)
    
  if (!(is.null(id) | is.na(id))) {
    if (delete) {
      deleteRunsFilter(src, filterName, motusProjID, clearOnly = TRUE)
    }
    df$filterID <- id

    dbInsertOrReplace(src, "runsFilters", df, replace = overwrite)
    message("Filter records saved")
  
  }
 
  dplyr::tbl(src, "runsFilters") %>% 
    dplyr::filter(.data$filterID == .env$id)
}