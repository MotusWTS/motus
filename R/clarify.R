#' Report or claim ambiguous tag detections
#'
#' A detections is "ambiguous" if the motus tag finder could not tell
#' which of several tags was detected, because they all produce the
#' same signal and were active at the same time.  The motus tag finder
#' uses tag deployment and lifetime metadata to decide what tags to
#' seek when, and notices when it can't distinguish between two or
#' more of them.  Detections of such tags during these periods of
#' overlap are assigned a negative motus tag ID that represents from 2
#' to 6 possible real motus tags.  The ambiguities might be real
#' (i.e. two or more tags transmitting the same signal and active at
#' the same time), or due to errors in tag registration or deployment
#' metadata.
#'
#' This function serves two purposes:
#'
#' - called with only a database, it reports the numbers of ambiguous detections
#' and what they could represent.
#' - called with `id`, it lets you claim some of the ambiguities as your own
#' tag, so that in subsequent processing, they will appear to be yours.
#'
#' This function does not (yet?) report your claim to motus.org
#'
#' WARNING: you cannot undo a claim within a copy of the database.  If
#' unsure, copy the .motus file first, then run `clarify` on only
#' one copy.
#'
#'
#' @param id if not missing, a vector of negative motus ambiguous tag IDs for
#'   which you wish to claim detections.  If missing, all tags are claimed over
#'   any period specified by `from` and `to`.
#' @param from Character. If not missing, the start time for your claim to
#'   ambiguous detections of tag(s) `id`.  If missing, you are claiming all
#'   detections up to `to`.  `from` can be a numeric timestamp, or a character
#'   string compatible with `lubridate::ymd()`
#' @param to Character. If not missing, the end time for your claim to ambiguous
#'   detections of tag(s) `id`.  If missing, you are claiming all detections
#'   after `from`. `to` can be a numeric timestamp, or a character string
#'   compatible with `lubridate::ymd()`
#' @param all.mine Logical. If TRUE, claim all ambiguous detections. In this
#'   case, `id`, `from` and `to` are ignored.
#'   
#' @inheritParams args
#' 
#' @details 
#'
#' If both `from` and `to` are missing, then all detections of ambiguous tag(s)
#' `id` are claimed.
#'
#' Parameters `id`, `from`, and `to` are recycled to the length of the longest
#' item.
#'
#' When you claim an ambiguous tag `T` for a period, any runs of `T` which
#' overlap that period at all are claimed entirely, even if they extend beyond
#' the period; i.e. runs are not split.
#'
#' @examples
#' 
#' \dontrun{
#' s <- tagme(57)         # get the tag database for project 57
#' clarify(s)             # report on the ambiguous tag detections in s
#' clarify(all.mine = TRUE) # claim all ambiguous tag detections as mine
#' clarify(id = -57)      # claim all detections of ambiguous tag -57 as mine
#' 
#' clarify(id = c(-72, -88, -91), from = "2017-01-02", to = "2017-05-06")
#' # claim all detections of ambiguous tags -72, -88, and -91 from
#' #   January 2 through May 6, 2017, as mine
#' }
#'
#' @return With no parameters, returns a summary data frame of ambiguous tag
#'   detections
#'
#' @export

clarify <- function(src, id, from, to, all.mine = FALSE) {
  
    if (missing(id) && ! all.mine) {
        ## report on ambiguities

        ## detections by ambiguous tag
        ambig <- DBI_Query(
        src, 
        "SELECT ",
        "  tmap.ambigID,
           tcount.numHits,
           tmap.id1,
           tmap.fullID1,
           tmap.id2,
           tmap.fullID2,
           tmap.id3,
           tmap.fullID3,
           tmap.id4,
           tmap.fullID4,
           tmap.id5,
           tmap.fullID5,
           tmap.id6,
           tmap.fullID6,
           tclar.tagID AS motusTagID,
           tclar.tsStart,
           tclar.tsEnd ",
        "FROM ",
        "( ",
        "  SELECT DISTINCT ",
        "    t1.ambigID AS ambigID,
             t2.tagID AS id1,
             t2.fullID AS fullID1,
             t3.tagID AS id2,
             t3.fullID AS fullID2,
             t4.tagID AS id3,
             t4.fullID AS fullID3,
             t5.tagID AS id4,
             t5.fullID AS fullID4,
             t6.tagID AS id5,
             t6.fullID AS fullID5,
             t7.tagID AS id6,
             t7.fullID AS fullID6 ",
        "  FROM ",
        "    tagAmbig AS t1
             LEFT JOIN tagDeps AS t2 ON t2.tagID = t1.motusTagID1
             LEFT JOIN tagDeps AS t3 ON t3.tagID = t1.motusTagID2
             LEFT JOIN tagDeps AS t4 ON t4.tagID = t1.motusTagID3
             LEFT JOIN tagDeps AS t5 ON t5.tagID = t1.motusTagID4
             LEFT JOIN tagDeps AS t6 ON t6.tagID = t1.motusTagID5
             LEFT JOIN tagDeps AS t7 ON t7.tagID = t1.motusTagID6 ",
        "  ORDER BY ", 
        "    t1.ambigID DESC",
        ") AS tmap ",
        
        "LEFT JOIN ", 
        "( ",
        "  SELECT ", 
        "     motusTagID AS ambigID, ", 
        "     IFNULL(sum(len), 0) AS numHits ",
        "  FROM ",
        "    runs ",
        "  WHERE ",
        "    motusTagID < 0 ",
        "  GROUP BY ",
        "    motusTagID ",
        "  ORDER BY ",
        "    motusTagID ",
        ") AS tcount ON tmap.ambigID = tcount.ambigID ", 
        
        "LEFT JOIN ",
        "clarified AS tclar ON tmap.ambigID = tclar.ambigID")
        
        if (nrow(ambig) == 0) {
            warning("No ambiguous detections in this tag database.", call. = FALSE)
        }

        return(ambig)
    }
    if (all.mine) {
        ## now update
      DBI_Execute(
        src, 
        "INSERT OR IGNORE INTO clarified (ambigID, tagID) ", 
        "SELECT DISTINCT t1.ambigID, t2.tagID FROM tagAmbig as t1 ",
        "JOIN tagDeps AS t2 ON ",
        "  t1.motusTagID1 = t2.tagID
           or t1.motusTagID2 = t2.tagID
           or t1.motusTagID3 = t2.tagID
           or t1.motusTagID4 = t2.tagID
           or t1.motusTagID5 = t2.tagID
           or t1.motusTagID6 = t2.tagID ",
        "WHERE ",
        "  t2.projectID = (SELECT val FROM meta WHERE key = 'tagProject') ",
        "ORDER BY ",
        "  t1.ambigID DESC, t2.tagID")

      map <- DBI_Query(src, "SELECT * FROM clarified")
      DBI_Execute(
      src, 
      "UPDATE runs SET motusTagID = ( ",
      "  SELECT tagID FROM clarified WHERE ",
      "    clarified.ambigID = runs.motusTagID AND clarified.tsStart IS NULL) ",
      "WHERE motusTagID < 0")
      
        if (any(duplicated(map$ambigID)))
            warning("Some ambiguous detections were resolved by choosing between\n",
                    "two of *your* tags, instead of between one of your tags and\n",
                    "one from a different project.\n",
                    "In each case, the tag with the smaller motusID was used.", 
                    call. = FALSE)

        message("To see how ambiguous tags were resolved, you can do `clarify(s)`")
    } else {
        ## TODO limited claims
        idfromto <- cbind(id, from, to)
        stop("Not yet implemented", call. = FALSE)
    }
}
