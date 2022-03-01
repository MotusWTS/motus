#' Create alltags view
#'
#' Creates a virtual table (really a 'view') in a motus database that
#' links each tag detection to all metadata available for the tag and
#' receiver, excluding GPS metadata.
#'
#' @param db dplyr src_sqlite to detections database
#' @param name character scalar; name for the virtual table.
#'     Default: 'alltags'.
#'
#' @note The new virtual table replaces any previous virtual table by the same
#' name in `db`.  The virtual table is an SQL VIEW, which will persist in `db`
#' across R sessions.
#'
#' @noRd
#'
#' @details Implementation details:
#'
#' For both tags and receivers, deployment meta-data has to be looked
#' up by detection ("hit") timestamp; i.e. we need the latest
#' deployment record which is still before the hit timestamp.  So we
#' are joining the hit table to the deployment table by a timestamp on
#' the hit and a greatest lower bound for that timestamp in the
#' deployment table.  It would be nice if there were an SQL
#' "LOWER JOIN" operator, which instead of joining on exact key value,
#' would join a key on the left to its greatest lower bound on the
#' right.  (and similarly, an "UPPER JOIN" operator to bind to the
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
#'
#'
makeAlltagsView = function(db, name="alltags") {
    query = paste0("CREATE VIEW IF NOT EXISTS ", name, " AS
SELECT
   t1.hitID as hitID,
   t1.runID as runID,
   t1.batchID as batchID,
   t1.ts as ts,
   CASE WHEN t6.utcOffset is null then t1.ts else t1.ts - t6.utcOffset * 60 * 60 end as tsCorrected,
   t1.sig as sig,
   t1.sigSD as sigsd,
   t1.noise as noise,
   t1.freq as freq,
   t1.freqSD as freqsd,
   t1.slop as slop,
   t1.burstSlop as burstSlop,
   t2.done as done,
   CASE WHEN t12.motusTagID is null then t2.motusTagID else t12.motusTagID end as motusTagID,
   t12.ambigID as ambigID,
   t2.ant as port,
   t2.nodeNum as nodeNum,
   t2.len as runLen,
   t2.motusFilter as motusFilter,
   t3.monoBN as bootnum,
   t4.projectID as tagProjID,
   t4.mfgID as mfgID,
   t4.type as tagType,
   t4.codeSet as codeSet,
   t4.manufacturer as mfg,
   t4.model as tagModel,
   t4.lifeSpan as tagLifespan,
   t4.nomFreq as nomFreq,
   t4.bi as tagBI,
   t4.pulseLen as pulseLen,
   t5.deployID as tagDeployID,
   t5.speciesID as speciesID,
   t5.markerNumber as markerNumber,
   t5.markerType as markerType,
   t5.tsStart as tagDeployStart,
   t5.tsEnd as tagDeployEnd,
   t5.latitude as tagDepLat,
   t5.longitude as tagDepLon,
   t5.elevation as tagDepAlt,
   t5.comments as tagDepComments,
   t5.test as tagDeployTest,
   ifnull(t5.fullID, printf('?proj?-%d#%s:%.1f', t5.projectID, t4.mfgID, t4.bi)) as fullID,
   t3.motusDeviceID as deviceID,
   t6.deployID as recvDeployID,
   t6.latitude as recvDeployLat,
   t6.longitude as recvDeployLon,
   t6.elevation as recvDeployAlt,
   t6a.serno as recv,
   t6.name as recvDeployName,
   t6.siteName as recvSiteName,
   t6.isMobile as isRecvMobile,
   t6.projectID as recvProjID,
   t6.utcOffset as recvUtcOffset,
   t7.antennaType as antType,
   t7.bearing as antBearing,
   t7.heightMeters as antHeight,
   t8.english as speciesEN,
   t8.french as speciesFR,
   t8.scientific as speciesSci,
   t8.`group` as speciesGroup,
   t9.label as tagProjName,
   t10.label as recvProjName
FROM
   hits AS t1
LEFT JOIN
   runs AS t2 ON t1.runID = t2.runID

left join allambigs t12 on t2.motusTagID = t12.ambigID

LEFT JOIN
   batches AS t3 ON t3.batchID = t1.batchID

LEFT JOIN
   tags AS t4 ON t4.tagID = CASE WHEN t12.motusTagID is null then t2.motusTagID else t12.motusTagID end

LEFT JOIN
   tagDeps AS t5 ON t5.tagID = CASE WHEN t12.motusTagID is null then t2.motusTagID else t12.motusTagID end
      AND t5.tsStart =
         (SELECT
             max(t5b.tsStart)
          FROM
             tagDeps AS t5b
          WHERE
             t5b.tagID = CASE WHEN t12.motusTagID is null then t2.motusTagID else t12.motusTagID end
             AND t5b.tsStart <= t1.ts
             AND (t5b.tsEnd IS NULL OR t5b.tsEnd >= t1.ts)
         )
LEFT JOIN
   recvs as t6a on t6a.deviceID = t3.motusDeviceID
LEFT JOIN
   recvDeps AS t6 ON t6.deviceID = t3.motusDeviceID AND
      t6.tsStart =
         (SELECT
             max(t6b.tsStart)
          FROM
             recvDeps AS t6b
          WHERE
             t6b.deviceID = t3.motusDeviceID
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
   projs AS t10 ON t10.ID = t6.projectID;
")

    DBI::dbExecute(db$con, paste0("DROP VIEW IF EXISTS ", name))
    DBI::dbExecute(db$con, query)
    return(dplyr::tbl(db, name))
}
