sql_versions <- dplyr::tibble()


# Update 2019-04-22 -------------------------------------------------------
sql_versions <- rbind(
   sql_versions,
   cbind(date = "2019-04-22",
         descr = "Add 'utcOffset' field to 'recvDeps' table",
         sql = "ALTER TABLE recvDeps ADD COLUMN utcOffset INTEGER"))


# Update 2019-03-13 -------------------------------------------------------
sql_versions <- rbind(
   sql_versions, 
   cbind(date = "2019-03-13",
         descr = "Create new 'activity' table",
         sql = "CREATE TABLE IF NOT EXISTS activity (
                batchID INTEGER,
                motusDeviceID INTEGER,
                ant TINYINT,
                year INTEGER,
                month INTEGER,
                day INTEGER,
                hourbin INTEGER,
                numTags INTEGER,
                pulseCount INTEGER,
                numRuns INTEGER,
                numHits INTEGER,
                run2 INTEGER,
                run3 INTEGER,
                run4 INTEGER,
                run5 INTEGER,
                run6 INTEGER,
                run7plus INTEGER,
         UNIQUE(batchID, ant, hourbin),
         PRIMARY KEY (batchID, ant, hourbin));")
)

# Update 2018-06-12 22:00:01 ---------------------------------------------------
sql_versions <- rbind(sql_versions, 
                      cbind(date = "2018-06-12 22:00:01",
                            descr = "Create new version of alltags that includes additional deployment fields",
                            sql = 
"CREATE VIEW IF NOT EXISTS alltags
AS
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
   t2.ant as port,
   t2.len as runLen,
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
   t5.comments as tagDeployComments,
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
   t10.label as recvProjName,
   t11.lat as gpsLat,
   t11.lon as gpsLon,
   t11.alt as gpsAlt
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
         );"))

# Update 2018-06-12 22:00:00 ---------------------------------------------------
sql_versions <- rbind(sql_versions,
                      cbind(date = "2018-06-12 22:00:00",
                            descr = "Remove previous version of alltags",
                            sql = "DROP VIEW IF EXISTS alltags"))

# Update 2018-02-28 -------------------------------------------------------

sql_versions <- rbind(sql_versions,
                      cbind(date = "2018-02-28 17:58:00",
                            descr = "Create new table for custom tag metadata",
                            sql = 
"CREATE TABLE IF NOT EXISTS tagProps (
    tagID INTEGER NOT NULL,
    deployID INTEGER NOT NULL,
    propID INTEGER PRIMARY KEY,
    propName TEXT NOT NULL,
    propValue TEXT NULL
);

CREATE INDEX IF NOT EXISTS tagProps_deployID ON tagProps (
    deployID ASC
);"))

# Update 2018-01-12 14:35 -------------------------------------------------------

sql_versions <- rbind(sql_versions,
                      cbind(date = "2018-01-12 14:35:00",
                            descr = "Create (or modify previous version of) runsFilters",
                            sql = 
"CREATE TABLE IF NOT EXISTS runsFilters (
   filterID  INTEGER NOT NULL,
    runID INTEGER NOT NULL,
    motusTagID  INTEGER NOT NULL,
    probability REAL NOT NULL,
    PRIMARY KEY(filterID,runID,motusTagID)
);

CREATE TEMPORARY TABLE runsFiltersTemp as SELECT * from runsFilters;

DROP TABLE IF EXISTS runsFilters;

CREATE TABLE IF NOT EXISTS runsFilters (
   filterID  INTEGER NOT NULL,
    runID INTEGER NOT NULL,
    motusTagID  INTEGER NOT NULL,
    probability REAL NOT NULL,
    PRIMARY KEY(filterID,runID,motusTagID)
);

CREATE INDEX IF NOT EXISTS runsFilters_filterID_runID_motusTagID ON runsFilters (
   filterID  ASC,
   runID  ASC,
   motusTagID   ASC,
   probability  ASC
);

INSERT INTO runsFilters SELECT * from runsFiltersTemp;

DROP TABLE IF EXISTS runsFiltersTemp;"))




# Update 2018-01-12 14:34 -----------------------------------------------------
sql_versions <- rbind(sql_versions,
                      cbind(date = "2018-01-12 14:34:00",
                            descr = "Create (or modify previous version of) filters",
                            sql = 
"CREATE TABLE IF NOT EXISTS filters (
   filterID  INTEGER PRIMARY KEY,
   userLogin   TEXT NOT NULL,
   filterName   TEXT NOT NULL,
   motusProjID  INTEGER NOT NULL,
   descr  TEXT,
   lastModified TEXT NOT NULL
);

CREATE TEMPORARY TABLE filtersTemp as SELECT * from filters;

DROP TABLE IF EXISTS filters;

CREATE TABLE IF NOT EXISTS filters (
   filterID  INTEGER PRIMARY KEY,
   userLogin   TEXT NOT NULL,
   filterName   TEXT NOT NULL,
   motusProjID  INTEGER NOT NULL,
   descr  TEXT,
   lastModified TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS filters_filterName_motusProjID ON filters (
   filterName ASC,
   motusProjID ASC
);

INSERT INTO filters SELECT * from filtersTemp;

DROP TABLE IF EXISTS filtersTemp;"))





# Update 2017-11-30 -------------------------------------------------------
sql_versions <- rbind(sql_versions,
                      cbind(date = "2017-11-30 19:31:00",
                            descr = "Add a new column 'siteName' to table 'recvDeps'.",
                            sql = "ALTER TABLE recvDeps ADD COLUMN siteName TEXT"))


# Update 2017-11-28 -------------------------------------------------------
sql_versions <- rbind(sql_versions,
                      cbind(date = "2017-11-28 14:25:00",
                            descr = "Remove empty gps detections",
                            sql = "DELETE FROM gps where lat = 0 and lon = 0 and alt = 0;"))

# Update 2017-11-27 -------------------------------------------------------
sql_versions <- rbind(sql_versions,
                      cbind(date = "2017-11-27 20:00:02",
                            descr = "Remove previous version of alltagswithambigs view",
                            sql = "DROP VIEW IF EXISTS alltagswithambigs"))


# Update 2017-10-24 -------------------------------------------------------
sql_versions <- rbind(sql_versions,
                      cbind(date = "2017-10-24 12:12:30",
                            descr = "Create new view allambigs that converts ambig columns into rows",
                            sql = 
"CREATE VIEW IF NOT EXISTS allambigs
as
SELECT ambigID, motusTagID1 as motusTagID FROM tagAmbig where motusTagID1 is not null
UNION SELECT ambigID, motusTagID2 as motusTagID FROM tagAmbig where motusTagID2 is not null
UNION SELECT ambigID, motusTagID3 as motusTagID FROM tagAmbig where motusTagID3 is not null
UNION SELECT ambigID, motusTagID4 as motusTagID FROM tagAmbig where motusTagID4 is not null
UNION SELECT ambigID, motusTagID5 as motusTagID FROM tagAmbig where motusTagID5 is not null
UNION SELECT ambigID, motusTagID6 as motusTagID FROM tagAmbig where motusTagID6 is not null"))

sql_versions <- dplyr::mutate(sql_versions, 
                              date = lubridate::as_datetime(as.character(date), tz = "UTC"))
usethis::use_data(sql_versions, internal = TRUE, overwrite = TRUE)







