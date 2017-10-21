#' Ensures that the motus sqlite file is up-to-date to support the current version of the package.
#'
#' This function is called from the z.onLoad function which adds a hook to the ensureDBTables function of the motusClient package.
#' addHook("ensureDBTables", updateMotusDb). I.E., the current function will be called each time that a new motus file is opened
#' (and the ensureDBTables function is accessed).
#'
#' @param rv return value
#' @param src sqlite database source
#' @param projRecv parameter provided by the hook function call, when opening a file built by project ID
#' @param deviceID parameter provided by the hook function call, when opening a file built by receiver ID
#' @export
#' @author Denis Lepage \email{dlepage@@bsc-eoc,org}
#'
#' @return rv

updateMotusDb = function(rv, src, projRecv, deviceID) {

print("updateMotusDb started")

# 16/10/2017 add deployID fields to the alltags view (drop and recreate the alltags view).

      if (0 == nrow(DBI::dbGetQuery(src$con, "select * from sqlite_master where tbl_name='alltags' and sql glob '* recvDeployLat *'"))) {
         print("recreate alltags")
         DBI::dbExecute(src$con, "DROP VIEW alltags")
         DBI::dbExecute(src$con, "CREATE VIEW alltags AS
SELECT
   t1.hitID as hitID,
   t1.runID as runID,
   t1.batchID as batchID,
   t1.ts as ts,
   t1.sig as sig,
   t1.sigSD as sigsd,
   t1.noise as noise,
   t1.freq as freq,
   t1.freqSD as freqsd,
   t1.slop as slop,
   t1.burstSlop as burstSlop,
   t2.done as done,
   t2.motusTagID as motusTagID,
   t2.ant as ant,
   t2.len as runLen,
   t3.monoBN as bootnum,
   t4.projectID as tagProjID,
   t4.mfgID as id,
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
   t5.latitude as depLat,
   t5.longitude as depLon,
   t5.elevation as depAlt,
   t5.comments as comments,
   t5.tsStartCode as startCode,
   t5.tsEndCode as endCode,
   ifnull(t5.fullID, printf('?proj?-%d#%s:%.1f', t5.projectID, t4.mfgID, t4.bi)) as fullID,
   t6.deployID as recvDeployID,
   t6.latitude as recvDeployLat,
   t6.longitude as recvDeployLon,
   t6.elevation as recvDeployElevation,
   t6.serno as recv,
   t6.name as site,
   t6.isMobile as isMobile,
   t6.projectID as projID,
   t7.antennaType as antType,
   t7.bearing as antBearing,
   t7.heightMeters as antHeight,
   t7.cableLengthMeters as cableLen,
   t7.cableType as cableType,
   t7.mountDistanceMeters as mountDistance,
   t7.mountBearing as mountBearing,
   t7.polarization1 as polarization1,
   t7.polarization2 as polarization2,
   t8.english as spEN,
   t8.french as spFR,
   t8.scientific as spSci,
   t8.`group` as spGroup,
   t9.label as tagProj,
   t10.label as proj,
   t11.lat as lat,
   t11.lon as lon,
   t11.alt as alt

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
         )")
      }

# 16/10/2017 create a new view that transposes the tagAmbig in rows

	DBI::dbExecute(src$con,	
"CREATE VIEW IF NOT EXISTS allambigs
as
SELECT ambigID, motusTagID1 as motusTagID FROM tagAmbig where motusTagID1 is not null
UNION SELECT ambigID, motusTagID2 as motusTagID FROM tagAmbig where motusTagID2 is not null
UNION SELECT ambigID, motusTagID3 as motusTagID FROM tagAmbig where motusTagID3 is not null
UNION SELECT ambigID, motusTagID4 as motusTagID FROM tagAmbig where motusTagID4 is not null
UNION SELECT ambigID, motusTagID5 as motusTagID FROM tagAmbig where motusTagID5 is not null
UNION SELECT ambigID, motusTagID6 as motusTagID FROM tagAmbig where motusTagID6 is not null"
	)
	
# 16/10/2017 create a new view that combines the detections with the allambigs view (duplicating ambiguous hits among all possible tags)
	
	DBI::dbExecute(src$con,	
"CREATE VIEW IF NOT EXISTS alltagswithambigs
as
SELECT
   t1.hitID as hitID,
   t1.runID as runID,
   t1.batchID as batchID,
   t1.ts as ts,
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
   t2.ant as ant,
   t2.len as runLen,
   t3.monoBN as bootnum,
   t4.projectID as tagProjID,
   t4.mfgID as id,
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
   t5.latitude as depLat,
   t5.longitude as depLon,
   t5.elevation as depAlt,
   t5.comments as comments,
   t5.tsStartCode as startCode,
   t5.tsEndCode as endCode,
   ifnull(t5.fullID, printf('?proj?-%d#%s:%.1f', t5.projectID, t4.mfgID, t4.bi)) as fullID,
   t6.deployID as recvDeployID,
   t6.latitude as recvDeployLat,
   t6.longitude as recvDeployLon,
   t6.elevation as recvDeployElevation,
   t6.serno as recv,
   t6.name as site,
   t6.isMobile as isMobile,
   t6.projectID as projID,
   t7.antennaType as antType,
   t7.bearing as antBearing,
   t7.heightMeters as antHeight,
   t7.cableLengthMeters as cableLen,
   t7.cableType as cableType,
   t7.mountDistanceMeters as mountDistance,
   t7.mountBearing as mountBearing,
   t7.polarization1 as polarization1,
   t7.polarization2 as polarization2,
   t8.english as spEN,
   t8.french as spFR,
   t8.scientific as spSci,
   t8.`group` as spGroup,
   t9.label as tagProj,
   t10.label as proj,
   t11.lat as lat,
   t11.lon as lon,
   t11.alt as alt
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
         )")
		
   return(rv)
   }

