#' create a virtual table of tag detections linked with all metadata.
#'
#' Creates a virtual table (really a 'view') in a motus database that
#' links each tag detection to all metadata available for the tag and
#' receiver.
#'
#' @param db dplyr src_sqlite to detections database
#'
#' @param name character scalar; name for the virtual table.
#'     Default: 'alltags'.
#'
#' @return a dplyr::tbl which refers to the newly-created virtual table.
#'
#' @note The new virtual table replaces any previous virtual table by the same
#' name in \code{db}.  The virtual table is an SQL VIEW, which will persist in \code{db}
#' across R sessions.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}
#'
#' Implementation details:
#'
#' For both tags and receivers, deployment meta-data has to be looked
#' up by detection ("hit") timestamp; i.e. we need the latest
#' deployment record which is still before the hit timestamp.  So we
#' are joining the hit table to the deployment table by a timestamp on
#' the hit and a greatest lower bound for that timestamp in the
#' deployment table.  It would be nice if there were an SQL
#' "LOWER JOIN" operator, which instead of joining on exact key value,
#' would join a key on the left to its greatest lower bound on the
#' right.  (and similary, an "UPPER JOIN" operator to bind to the
#' least upper bound on the right.)  For keys with B-tree indexes,
#' this would be as fast as an exact join.
#'
#' We can instead code this as a subquery like so:
#'
#' CREATE TABLE hits (ts double, tagID integer);
#' CREATE TABLE tagDeps (tsStart double, tsEnd double, tagID integer, info char);
#'
#'    SELECT t1.*, t2.info from hits as t1 left join tagDeps as t2 on
#'    t2.tagID = t1.tagID and t2.tsStart = (select max(t3.tsStart) from
#'    tagDeps as t3 where t3.tagID=t2.tagID and t3.tsStart <= t1.ts and
#'    t3.tsEnd >= t1.ts)
#'
#' This will yield NA for the 'info' field when there is no tag
#' deployment covering the range.  Running EXPLAIN on this query in
#' sqlite suggests it optimizes well.

makeAlltagsView = function(db, name="alltags") {
    query = paste0("CREATE VIEW ", name, " AS
SELECT
   t1.*,
   t2.*,
   t3.*,
   t4.*,
   t5.tagID,
   t5.projectID,
   t5.deployID,
   t5.status,
   t5.tsStart,
   t5.tsEnd,
   t5.deferSec,
   t5.speciesID,
   t5.markerNumber,
   t5.markerType,
   t5.latitude,
   t5.longitude,
   t5.elevation,
   t5.comments,
   t5.id,
   t5.bi,
   t5.tsStartCode,
   t5.tsEndCode,
   ifnull(t5.fullID, printf('?proj?-%d#%s:%.1f', t4.projectID, t4.mfgID, t4.bi)) as fullID,
   t6.*,
   t7.*,
   t8.*,
   t9.*,
   t10.*,
   t11.*
FROM
   hits AS t1
LEFT JOIN
   runs AS t2 ON t1.runID = t2.runID

LEFT JOIN
   batches AS t3 ON t3.batchID = t1.batchID

LEFT JOIN
   tags AS t4 ON t4.tagID = t2.motusTagID

LEFT JOIN
   tagDeps AS t5 ON t5.tagID = t2.motusTagID
      AND t5.tsStart =
         (SELECT
             max(t5b.tsStart)
          FROM
             tagDeps AS t5b
          WHERE
             t5b.tagID = t2.motusTagID
             AND t5b.tsStart <= t1.ts
             AND (t5b.tsEnd IS NULL OR t5b.tsEnd >= t1.ts)
         )
LEFT JOIN
   recvDeps AS t6 ON t6.deviceID = t3.motusDeviceID AND
      t6.tsStart =
         (SELECT
             max(t6b.tsStart)
          FROM
             recvDeps AS t6b
          WHERE
             t6b.deviceID=t3.motusDeviceID
             AND t6b.tsStart <= t1.ts
             AND (t6b.tsEnd IS NULL OR t6b.tsEnd >= t1.ts)
         )

LEFT JOIN
   antDeps AS t7 ON t7.deployID = t6.deployID AND t7.port = t2.ant
LEFT JOIN
   species AS t8 ON t8.id = t5.speciesID
LEFT JOIN
   projs AS t9 ON t9.ID = t5.projectID
LEFT JOIN
   projs AS t10 ON t10.ID = t6.projectID
LEFT JOIN
   gps AS t11 ON t11.batchID = t3.batchID
      AND t11.ts =
         (SELECT
             max(t11b.ts)
          FROM
             gps AS t11b
          WHERE
             t11b.batchID=t3.batchID
             AND t11b.ts <= t1.ts
         )
")
    dbGetQuery(db$con, paste0("DROP VIEW IF EXISTS ", name))
    dbGetQuery(db$con, query)
    return(tbl(db, name))
}
