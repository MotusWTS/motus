#' report on or claim ambiguous tag detections
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
#' \itemize{
#' \item called with only a database dplyr::src, it reports the numbers
#' of ambiguous detections and what they could represent.
#' \item called with \code{id}, it lets you claim some of the ambiguities
#' as your own tag, so that in subsequent processing, they will appear
#' to be yours.
#' }
#'
#' This function does not (yet?) report your claim to motus.org
#'
#' WARNING: you cannot undo a claim within a copy of the database.  If
#' unsure, copy the .motus file first, then run \code{clarify} on only
#' one copy.
#'
#' @param s dplyr::src to the tag database, as returned by \code{tagme()}
#'
#' @param id if not missing, a vector of negative motus ambiguous tag IDs
#' for which you wish to claim detections.  If missing, all tags are claimed
#' over any period specified by \code{from} and \code{to}.
#'
#' @param from if not missing, the start time for your claim to
#'     ambiguous detections of tag(s) \code{id}.  If missing, you are
#'     claiming all detections up to \code{to}.  \code{from} can be a
#'     numeric timestamp, or a character string compatible with
#'     \code{lubridate::ymd}
#'
#' @param to if not missing, the end time for your claim to ambiguous
#'     detections of tag(s) \code{id}.  If missing, you are claiming
#'     all detections after \code{from}.  \code{to} can be a numeric
#'     timestamp, or a character string compatible with
#'     \code{lubridate::ymd}
#'
#' @param all.mine logical; if TRUE, claim all ambiguous detections.
#' In this case, \code{id, from} and \code{to} are ignored.
#'
#' If both \code{from} and \code{to} are missing, then all detections of
#' ambiguous tag(s) \code{id} are claimed.
#'
#' Parameters \code{id}, \code{from}, and \code{to} are recycled to the
#' length of the longest item.
#'
#' When you claim an ambiguous tag \code{T} for a period, any runs of \code{T}
#' which overlap that period at all are claimed entirely, even if they extend
#' beyond the period; i.e. runs are not split.
#'
#' @examples
#' ## s = tagme(57) ## get a dplyr::src to the tag database for project 57
#' ## clarify(s)  ## report on the ambiguous tag detections in s
#' ## clarify(all.mine=TRUE) ## claim all ambiguous tag detections as mine
#' ## clarify(id = -57) ## claim all detections of ambiguous tag -57 as mine
#' ## clarify(id = c(-72, -88, -91), from=("2017-01-02"), to=("2017-05-06")) 
#' ## claim all detections of ambiguous tags -72, -88, and -91 from
#' ##   January 2 through May 6, 2017, as mine
#'
#' @return with no parameters, returns a summary data frame of ambiguous tag detections, with these columns
#' \itemize{
#' \item ambigID; integer: negative motus ambiguous tag ID, representing multiple possible real tags
#' \item numHits; numeric: total number of detections of this ambiguity
#' \item id1; integer: first possible motus ID of real tag that this detection might represent
#' \item fullID1; character: fullID for first possible real tag, in "Project#MFGID:BI@NOMFREQ(M.MotusID)" format
#' \item id2; integer: second possible motus ID of real tag that this detection might represent
#' \item fullID2; character: fullID for second possible real tag, in same format as fullID1
#' \item ...
#' \item id6; integer: sixth possible motus ID of real tag that this detection might represent
#' \item fullID6; character: fullID for sixth possible real tag, in same format as fullID1
#' \item motusTagID; integer tag ID ambiguity was resolved to over some period
#' \item tsStart; numeric: timestamp of start of period for this ambiguity resolution
#' \item tsEnd; numeric: timestamp of end of period for this ambiguity resolution
#' }
#'
#' @export

clarify = function(s, id, from, to, all.mine=FALSE) {
    sql = safeSQL(s$con)
    if (missing(id) && ! all.mine) {
        ## report on ambiguities

        ## detections by ambiguous tag
        ambig = sql("
select
   tmap.ambigID,
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
   tclar.tagID as motusTagID,
   tclar.tsStart,
   tclar.tsEnd
from
   (
   select distinct
      t1.ambigID as ambigID,
      t2.tagID as id1,
      t2.fullID as fullID1,
      t3.tagID as id2,
      t3.fullID as fullID2,
      t4.tagID as id3,
      t4.fullID as fullID3,
      t5.tagID as id4,
      t5.fullID as fullID4,
      t6.tagID as id5,
      t6.fullID as fullID5,
      t7.tagID as id6,
      t7.fullID as fullID6
   from
      tagAmbig as t1
      left join tagDeps as t2 on t2.tagID = t1.motusTagID1
      left join tagDeps as t3 on t3.tagID = t1.motusTagID2
      left join tagDeps as t4 on t4.tagID = t1.motusTagID3
      left join tagDeps as t5 on t5.tagID = t1.motusTagID4
      left join tagDeps as t6 on t6.tagID = t1.motusTagID5
      left join tagDeps as t7 on t7.tagID = t1.motusTagID6
   order by
      t1.ambigID desc
   ) as tmap

   left join

   (
   select
      motusTagID as ambigID,
      ifnull(sum(len), 0) as numHits
   from
      runs
   where
      motusTagID < 0
   group by
      motusTagID
   order by
      motusTagID
   ) as tcount on tmap.ambigID = tcount.ambigID

   left join

   clarified as tclar on tmap.ambigID = tclar.ambigID

")
        if (nrow(ambig) == 0) {
            warning("No ambiguous detections in this tag database.\n")
        }

        return(ambig)
    }
    if (all.mine) {
        ## now update
        sql("

insert or ignore into clarified
   (
      ambigID,
      tagID
   )
   select distinct
      t1.ambigID,
      t2.tagID
   from
      tagAmbig as t1
      join tagDeps as t2 on
            t1.motusTagID1 = t2.tagID
         or t1.motusTagID2 = t2.tagID
         or t1.motusTagID3 = t2.tagID
         or t1.motusTagID4 = t2.tagID
         or t1.motusTagID5 = t2.tagID
         or t1.motusTagID6 = t2.tagID
   where
      t2.projectID = ( select val from meta where key = 'tagProject' )
   order by
      t1.ambigID desc, t2.tagID
")
        map = sql("select * from clarified")
        sql("
update
   runs
set
   motusTagID =
      (
      select
         tagID
      from
         clarified
      where
         clarified.ambigID = runs.motusTagID
         and clarified.tsStart is null
      )
where
   motusTagID < 0
")
        if (any(duplicated(map$ambigID)))
            warning("Some ambiguous detections were resolved by choosing between\n",
                    "two of *your* tags, instead of between one of your tags and\n",
                    "one from a different project.\n",
                    "In each case, the tag with the smaller motusID was used.\n")

        message("To see how ambiguous tags were resolved, you can do `clarify(s)`")
    } else {
        ## TODO limited claims
        idfromto = cbind(id, from, to)
        stop("Not yet implemented", call. = FALSE)
    }
}
