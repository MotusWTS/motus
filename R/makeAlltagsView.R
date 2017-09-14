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
#' By default, the columns in the virtual table are:
#' \itemize{
#'    \item{hitID} unique motus ID for this tag detection
#'    \item{runID} unique motus ID for the run this detection belongs to
#'    \item{batchID} unique motus ID for the processing batch this detection came from
#'    \item{ts} timestamp, in seconds since 1 Jan, 1970 GMT
#'    \item{sig} signal strength, in dB (max) for SG; raw value for Lotek receiver
#'    \item{sigSD} sd among pulses of signal strength (SG); NA for Lotek
#'    \item{noise} noise strength, in dB (max) for SG; NA for Lotek
#'    \item{freq} offset in kHz from listening frequency for SG; NA for Lotek
#'    \item{freqSD} sd among pulses of offset in kHz from listening frequency for SG; NA for Lotek
#'    \item{slop} total absolute difference (milliseconds) in intrer-pulse gaps between registration and detection for SG; NA for Lotek
#'    \item{burstSlop} signed difference (seconds) between detection and registration burst intervals
#'    \item{done} logical: is run finished?
#'    \item{motusTagID} unique motus ID for this physical tag
#'    \item{ant} antenna number
#'    \item{runLen} length of run (# of bursts detected)
#'    \item{bootnum} boot session of receiver for SG; NA for Lotek
#'    \item{tagProjID} unique motus ID for project tag was deployed by
#'    \item{id} manufacturer ID
#'    \item{tagType}
#'    \item{codeSet} for coded ID tags, the name of the codeset
#'    \item{mfg} tag manufacturer
#'    \item{tagModel} manufacturer's model name for tag
#'    \item{tagLifespan} estimated tag lifespan
#'    \item{nomFreq} nominal tag frequency (MHz)
#'    \item{tagBI} tag burst interval (seconds)
#'    \item{pulseLen} tag pulse length (milliseconds) if applicable
#'    \item{speciesID} unique motusID for species tag was deployed on
#'    \item{markerNumber} number for additional marker placed on organism (e.g. bird band #)
#'    \item{markerType} type of additional marker
#'    \item{depLat} latitude of tag deployment, in decimal degrees N
#'    \item{depLon} longitude of tag deployment, in decimal degrees E
#'    \item{depAlt} altitude of tag deployment, in metres ASL
#'    \item{comments} additional comments or unclassified metadata for tag (often in JSON format)
#'    \item{startCode} integer code giving method for determining tag deployment start timestamp
#'    \item{endCode} integer code giving method for determining tag deployment end timestamp
#'    \item{fullID} full tag ID as PROJECT#MFGID:BI@NOMFREQ (but this is not necessarily unique over time; see motusTagID for a unique tag id)
#'    \item{recv} serial number of receiver; e.g. SG-1234BBBK5678 or Lotek-12345
#'    \item{site} short name for receiver deployment location
#'    \item{isMobile} logical; was this a mobile receiver deployment?
#'    \item{projectID} integer; unique motus ID for the project that deployed this receiver
#'    \item{antType} character; antenna type; e.g. "omni", "yagi-5", ...
#'    \item{antBearing} numeric; direction antenna main axis points in; degrees clockwise from local magnetic north
#'    \item{antHeight} numeric; height (metres) of antenna main axis above ground
#'    \item{cableLen} numeric; length (metres) of coaxial cable connecting antenna to radio
#'    \item{cableType} character; type of coaxial cable
#'    \item{mountDistance} numeric; distance (metres) between antenna mounting and receiver
#'    \item{mountBearing} numeric; bearing from receiver to base of antenna mounting, in degrees clockwise from local magnetic north
#'    \item{polarization1} numeric; antenna polarization angle: azimuth component (degrees clockwise from local magnetic north)
#'    \item{polarization2} numeric; antenna polarization angle: elevation component (degrees above horizon)
#'    \item{spEN} species name in english
#'    \item{spFR} species name in french
#'    \item{spSci} species scientific name
#'    \item{spGroup} species group
#'    \item{tagProj} short label of project that deployed tag
#'    \item{proj} short label of project that deployed receiver
#'    \item{lat} latitude of receiver at tag detection time (degrees North)
#'    \item{lon} longitude of receiver at tag detection time (degrees East)
#'    \item{alt} altitude of receiver at tag detection time (metres)
#' }
#'
#' @note The new virtual table replaces any previous virtual table by the same
#' name in \code{db}.  The virtual table is an SQL VIEW, which will persist in \code{db}
#' across R sessions.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}
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
#'
#'
makeAlltagsView = function(db, name="alltags") {
    query = paste0("CREATE VIEW ", name, " AS
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
   ifnull(t11.lat, t6.latitude) as lat,
   ifnull(t11.lon, t6.longitude) as lon,
   ifnull(t11.alt, t6.elevation) as alt
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
    DBI::dbExecute(db$con, paste0("DROP VIEW IF EXISTS ", name))
    DBI::dbExecute(db$con, query)
    return(tbl(db, name))
}
