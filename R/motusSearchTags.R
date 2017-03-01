#' return a list of motus tags
#'
#' @param projectID: integer scalar; motus internal project ID
#'
#' @param tsStart: numeric scalar; start of active period
#'
#' @param tsEnd: numeric scalar; end of active period
#'
#' @param searchMode: character scalar; type of search
#'     desired. "overlaps" looks for tags active during at least a
#'     portion of the time span \code{c(tsStart, tsEnd)}, while
#'     "startsBetween" looks for tags with deployment start times in
#'     the same range.
#'
#' @param defaultLifeSpan: integer scalar; default lifespan of tags,
#'     in days; used when motus does not know the lifespan for a tag.
#'
#' @param lifeSpanBuffer: numeric scalar; amount by which nominal
#'     lifespan is multiplied to get maximum possible lifespan.
#'
#' @param regStart: numeric scalar; if not NULL, search for tags
#'     registered no earlier than this date, and ignore deployment
#'     dates.
#'
#' @param regEnd: numeric scalar; if not NULL, search for tags
#'     registered no later than this date, and ignore deployment
#'     dates.
#'
#' @param mfgID: character scalar; typically a small integer; return
#'     only records for tags with this manufacturer ID (usually
#'     printed on the tag)
#'
#' @param ...: additional parameters to motusQuery()
#'
#' @return the list of motus tags and their meta data satisfying the
#'     search criteria, or NULL if there are none.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusSearchTags = function(projectID = NULL, tsStart = NULL, tsEnd = NULL, searchMode=c("startsBetween", "overlaps"), defaultLifespan=90, lifespanBuffer=1.5, regStart = NULL, regEnd = NULL, mfgID = NULL, ...) {
    searchMode = match.arg(searchMode)
    rv = motusQuery(Motus$API_SEARCH_TAGS, requestType="get",
               list(
                   projectID = projectID,
                   tsStart   = tsStart,
                   tsEnd     = tsEnd,
                   searchMode = searchMode,
                   defaultLifespan = defaultLifespan,
                   lifespanBuffer = lifespanBuffer,
                   regStart  = regStart,
                   regEnd    = regEnd,
                   mfgID     = mfgID
               ), ...)

    return(subset(rv, ! grepl("^TEST", mfgID, perl=TRUE)))
}
