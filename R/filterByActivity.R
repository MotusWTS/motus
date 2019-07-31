
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
#' @param minLen Numeric. The minimum run length to allow (equal to or below
#'   this, all runs are 'bad')
#' @param maxLen Numeric. The maximum run length to allow (above this, all runs
#'   are 'good')
#' @param maxRuns Numeric. The cutoff of number of runs in a batch (see Details)
#' @param ratio Numeric. The ratio cutoff of runs length 2 to number of runs in
#'   a batch (see Details)
#' 
#' @details Runs are identified by the following: 
#' - All runs with a length >= `maxLen` are **GOOD**
#' - All runs with a length <= `minLen` are **BAD**
#' - Runs with a length between `minLen` and `maxLen` are **BAD** if both of the
#' following is true:
#'   - belong to a batch where the number of runs is >= `maxRuns`
#'   - the ratio of runs with a length of 2 to the number of runs total
#'     is >= `ratio`
#'
#' @return tbl_SQLiteConnection
#' @export
#'
#' @examples
#' \dontrun{
#' sql.motus <- tagme(176, new = TRUE, update = TRUE)
#' tbl_good <- filterByActivity(sql.motus)
#' tbl_bad <- filterByActivity(sql.motus, return = "bad")
#' tbl_all <- filterByActivity(sql.motus, return = "all")
#' }
#' 
#' 
filterByActivity <- function(src, return = "good", 
                             minLen = 2, maxLen = 5, 
                             maxRuns = 100, ratio = 0.85) {
  
  if(!return %in% c("good", "bad", "all")) {
    stop("'return' must be one of 'good', 'bad', or 'all'", call. = FALSE)
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
  
  if(any(!c("runs", "activity", "alltags") %in% t)) {
    stop("'src' must contain at least tables 'activity', 'alltags', and 'runs'", call. = FALSE)
  }
  
  tbl_runs <- dplyr::tbl(src$con, "runs") %>% 
    dplyr::mutate(hourBin = round(.data$tsBegin/3600, 0))
  
  tbl_activity <- dplyr::tbl(src$con, "activity")
  
  if(nrow(DBI::dbGetQuery(src$con, "SELECT * FROM activity LIMIT 1")) < 1) {
    stop("'activity' table is empty, cannot filter by activity", call. = FALSE)
  }

  tbl_bad <- dplyr::left_join(tbl_runs, tbl_activity, 
                              by = c("batchIDbegin" = "batchID", 
                                     "ant", "hourBin")) %>% 
    # Convert integers to numeric for ratio calculations
    dplyr::mutate(run2 = as.numeric(.data$run2),
                  numRuns = as.numeric(.data$numRuns)) %>%
    dplyr::filter(.data$len < maxLen) %>% # Filter out good runs
    dplyr::filter((.data$numRuns >= maxRuns & ((.data$run2 / .data$numRuns) >= ratio)) | 
                    .data$len <= minLen) %>%
    dplyr::select("runID") %>%
    dplyr::mutate(probability = 0)

  # Label runs with probability
  tbl_prob <- dplyr::tbl(src$con, "alltags") %>%
    dplyr::left_join(tbl_bad, by = "runID") %>%
    dplyr::mutate(probability = dplyr::if_else(is.na(.data$probability), 1, 
                                               .data$probability))
  
  # Which to return?
  if(return == "good") r <- dplyr::filter(tbl_prob, .data$probability > 0)
  if(return == "bad")  r <- dplyr::filter(tbl_prob, .data$probability == 0)
  if(return == "all")  r <- tbl_prob
  r
}