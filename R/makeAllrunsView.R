#' Create allruns view
#'
#' Creates a virtual table (really a 'view') in a motus database that
#' links each tag detection to all metadata available for the tag and
#' receiver. The allruns view is the same as alltags but excludes hits.
#'
#' @param db dplyr src_sqlite to detections database
#' @param name character scalar; name for the virtual table.
#'     Default: 'allruns'.
#'
#' @return a dplyr::tbl which refers to the newly-created virtual table.
#'
#' @note The new virtual table replaces any previous virtual table by the same
#' name in `db`.  The virtual table is an SQL VIEW, which will persist in `db`
#' across R sessions.
#'
#' @noRd
#'

makeAllrunsView <- function(db, name = "allruns") {
  query = glue::glue("
  CREATE VIEW IF NOT EXISTS {name} 
  AS
  SELECT
    t2.runID as runID,
    t3.batchID as batchID, 
    t2.done as done,
    CASE WHEN t12.motusTagID is null then t2.motusTagID else t12.motusTagID end as motusTagID,
    t12.ambigID as ambigID,
    t2.ant as port,
    t2.nodeNum as nodeNum,
    t2.len as runLen,
    t2.motusFilter as motusFilter,
    t2.tsBegin as tsBegin,
    t2.tsEnd as tsEnd,
    CASE WHEN t6.utcOffset is null then t2.tsBegin else t2.tsBegin - t6.utcOffset * 60 * 60 end as tsBeginCorrected,
    CASE WHEN t6.utcOffset is null then t2.tsEnd else t2.tsEnd - t6.utcOffset * 60 * 60 end as tsEndCorrected,
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
    t5.latitude as tagDeployLat,
    t5.longitude as tagDeployLon,
    t5.elevation as tagDeployAlt,
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
    runs AS t2
  LEFT JOIN
    allambigs t12 on t2.motusTagID = t12.ambigID
  LEFT JOIN
    batchRuns AS t3a ON t2.runID = t3a.runID
  LEFT JOIN
    batches AS t3 ON t3.batchID = t3a.batchID
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
           AND t5b.tsStart <= t2.tsBegin
           AND (t5b.tsEnd IS NULL OR t5b.tsEnd >= t2.tsBegin))
  LEFT JOIN
    recvs as t6a on t6a.deviceID =t3.motusDeviceID
  LEFT JOIN
    recvDeps AS t6 ON t6.deviceID = t3.motusDeviceID AND
      t6.tsStart =
        (SELECT
           max(t6b.tsStart)
         FROM
           recvDeps AS t6b
         WHERE
           t6b.deviceID=t3.motusDeviceID
           AND t6b.tsStart <= t2.tsBegin
           AND (t6b.tsEnd IS NULL OR t6b.tsEnd >= t2.tsBegin))
  LEFT JOIN
    antDeps AS t7 ON t7.deployID = t6.deployID AND t7.port = t2.ant
  LEFT JOIN
    species AS t8 ON t8.id = t5.speciesID
  LEFT JOIN
    projs AS t9 ON t9.ID = t5.projectID
  LEFT JOIN
    projs AS t10 ON t10.ID = t6.projectID")
  
  DBI::dbExecute(db$con, paste0("DROP VIEW IF EXISTS ", name))
  DBI::dbExecute(db$con, query)
  dplyr::tbl(db, name)
}
