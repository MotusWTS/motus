
#' Filter `alltags` by `activity`
#' 
#' The `activity` table is used to identify batches with too much noise.
#' Depending on the value of `return` these are filtered out, returned, or
#' identified in the `alltags` view with the column `probability`. **No changes
#' to the database are made.**
#'
#' @param src src_sqlite object representing the database
#' @param return Character. One of "good" (return only 'good' runs), "bad"
#'   (return only 'bad' runs), "all" (return all runs, but with a new
#'   `probability` column which identifies 'bad' (0) and 'good' (1) runs.
#' @param view Character. Which view to use, one of "alltags" (faster) or
#'   "alltagsGPS" (with GPS data).
#' @param minLen Numeric. The minimum run length to allow (equal to or below
#'   this, all runs are 'bad')
#' @param maxLen Numeric. The maximum run length to allow (equal to or above
#'   this, all runs are 'good')
#' @param maxRuns Numeric. The cutoff of number of runs in a batch (see Details)
#' @param ratio Numeric. The ratio cutoff of runs length 2 to number of runs in
#'   a batch (see Details)
#' 
#' @details Runs are identified by the following: 
#' - All runs with a length >= `maxLen` are **GOOD**
#' - All runs with a length <= `minLen` are **BAD**
#' - Runs with a length between `minLen` and `maxLen` are **BAD** IF both of the
#' following is true:
#'   - belong to a batch where the number of runs is >= `maxRuns`
#'   - the ratio of runs with a length of 2 to the number of runs total
#'     is >= `ratio`
#'
#' @return tbl_SQLiteConnection
#' @export
#'
#' @examples
#' 
#' #' # download and access data from project 176 in sql format
#' # usename and password are both "motus.sample"
#' \dontrun{sql.motus <- tagme(176, new = TRUE, update = TRUE)}
#' 
#' # OR use example sql file included in `motus`
#' sql.motus <- tagme(176, update = FALSE, 
#'                    dir = system.file("extdata", package = "motus"))
#' 
#' tbl_good <- filterByActivity(sql.motus)
#' tbl_bad <- filterByActivity(sql.motus, return = "bad")
#' tbl_all <- filterByActivity(sql.motus, return = "all")
#' 
#' 
filterByActivity <- function(src, return = "good", view = "alltags",
                             minLen = 3, maxLen = 5, 
                             maxRuns = 100, ratio = 0.85) {
  
  if(!return %in% c("good", "bad", "all")) {
    stop("'return' must be one of 'good', 'bad', or 'all'", call. = FALSE)
  }
  if(!view %in% c("alltags", "alltagsGPS")) {
    stop("'view' must be one of 'alltags' or 'alltagsGPS'", call. = FALSE)
  }
  if(any(!is.numeric(c(minLen, maxLen, maxRuns, ratio)))) {
    stop("'minLen', 'maxLen', 'maxRuns', and 'ratio' must all be numeric", call. = FALSE)
  }
  if(any(c(minLen, maxLen, maxRuns) < 1)) {
    stop("'minLen', 'maxLen', and 'maxRuns' must all be greater than 0", call. = FALSE)
  }
  if(ratio < 0 | ratio > 1) stop("'ratio' must be a value between 0 and 1", call. = FALSE)
  if(minLen > maxLen) stop("'minLen' must be smaller than or equal to 'maxLen'", call. = FALSE)
  
  t <- DBI::dbListTables(src$con)
  
  if(any(!c("runs", "activity", view) %in% t)) {
    stop(paste0("'src' must contain at least tables 'activity', '", view, 
                "', and 'runs'"), call. = FALSE)
  }
  
  tbl_runs <- dplyr::tbl(src$con, "runs") %>% 
    dplyr::mutate(hourBin = floor(.data$tsBegin/3600))
  
  tbl_activity <- dplyr::tbl(src$con, "activity")
  
  if(nrow(DBI::dbGetQuery(src$con, "SELECT * FROM activity LIMIT 1")) < 1) {
    stop("'activity' table is empty, cannot filter by activity", call. = FALSE)
  }

  # Get "bad" activity runIDs
  tbl_bad <- dplyr::left_join(tbl_runs, tbl_activity, 
                              by = c("batchIDbegin" = "batchID", 
                                     "ant", "hourBin")) %>% 
    # Convert integers to numeric for ratio calculations
    dplyr::mutate(run2 = as.numeric(.data$run2),
                  numRuns = as.numeric(.data$numRuns)) %>%
    dplyr::filter(.data$len < maxLen) %>% # Filter out good runs
    dplyr::filter((.data$numRuns >= maxRuns & ((.data$run2 / .data$numRuns) >= ratio)) | 
                    .data$len <= minLen) %>%
    dplyr::select("runID")
  
  # Label "bad" alltags 
  tbl_bad <- dplyr::tbl(src$con, view) %>%
    dplyr::left_join(tbl_bad, ., by = "runID") %>%
    dplyr::mutate(probability = 0)

  # All others are "good"
  tbl_good <- dplyr::tbl(src$con, view) %>%
    dplyr::anti_join(tbl_bad, by = "runID") %>%
    dplyr::mutate(probability = 1)

  # Which to return?
  if(return == "good") r <- dplyr::collect(tbl_good)
  if(return == "bad")  r <- dplyr::collect(tbl_bad)
  if(return == "all")  {
    r <- dplyr::collect(tbl_good) %>%
      dplyr::bind_rows(dplyr::collect(tbl_bad)) %>%
      dplyr::arrange(.data$ts)
  }
  r
}