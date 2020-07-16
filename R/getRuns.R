#' Returns a dataframe containing runs
#' 
#' Specifically the `runID` and `motusTagID`, `ambigID` and `tsBegin` to `tsEnd`
#' (timestamp) range of runs, filtered by optional parameters. The
#' `match.partial` parameter (default = TRUE) determines how timestamp filtering
#' works. When `match.partial` is FALSE, `runID`'s are only included when both
#' `tsBegin` and `tsEnd` falls between `ts.min` and `ts.max` (only includes runs
#' when they entirely contained in the specified range). When match.partial is
#' TRUE, `runID`'s are returned whenever the run partially matches the specified
#' period.
#'
#' @param src dplyr sqlite src, as returned by `dplyr::src_sqlite()`
#' @param ts.min minimum timestamp used to filter the dataframe, Default: NA 
#' @param ts.max maximum timestamp used to filter the dataframe, Default: NA  
#' @param match.partial whether runs that partially overlap the specified ts
#'   range are included, Default: TRUE
#' @param motusTagID vector of Motus tag ID's used to filter the resulting
#'   dataframe, Default: c()
#' @param ambigID vector of ambig ID's used to filter the resulting dataframe,
#'   Default: c()
#'
#' @return a dataframe containing the runID, the motusTagID and the ambigID (if applicable) of runs
#'
#' @export

getRuns = function(src, ts.min=NA, ts.max=NA, match.partial=TRUE, 
                   motusTagID=c(), ambigID=c()) {

  sqlq = function(...) DBI::dbGetQuery(src$con, sprintf(...))

  a = " where "
  sql = "select a.runID, IFNULL(b.motusTagID, a.motusTagID) as motusTagID, b.ambigID, tsBegin, tsEnd from runs a left join allambigs b on a.motusTagID = b.ambigID"
  if (!is.na(ts.min)) {
    if (match.partial)
		sql = paste(sql, a, sprintf("tsEnd >= %f", ts.min))
	else 
		sql = paste(sql, a, sprintf("tsBegin >= %f", ts.min))
	a = " and "
  }
  if (!is.na(ts.max)) {
    if (match.partial)
		sql = paste(sql, a, sprintf("tsBegin <= %f", ts.max))
	else 
		sql = paste(sql, a, sprintf("tsEnd <= %f", ts.max))
	a = " and "
  }
  if (length(motusTagID) > 0) {
	sql = paste(sql, a, sprintf("IFNULL(b.motusTagID, a.motusTagID) in (%s)", paste(motusTagID, collapse=",")))
	a = " and "
  }
  if (length(ambigID) > 0) {
	sql = paste(sql, a, sprintf("ambigID in (%s)", paste(ambigID, collapse=",")))
	a = " and "
  }
  
  return (sqlq(sql))
  
}