#' make sure a tag or receiver database has the required tables
#'
#' @param src dplyr sqlite src, as returned by `dplyr::src_sqlite()`
#' @param projRecv integer scalar motus project ID number *or* character scalar
#'   receiver serial number; must be specified if `src` does not already
#'   contain a table named `meta`.
#' @param deviceID integer scalar motus deviceID; must be specified when this is
#'   a new receiver database.
#'   
#' @return returns a dplyr::tbl representing the alltags virtual table which is
#'   created in `src`.
#' 
#' @noRd
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

ensureDBTables = function(src, projRecv, deviceID) {
  if (! inherits(src, "src_sql"))
    stop("src is not a dplyr::src_sql object")
  con = src$con
  if (! inherits(con, "SQLiteConnection"))
    stop("src is not open or is corrupt; underlying db connection invalid")
  
  ## function to send a single statement to the underlying connection
  sql = function(...) DBI::dbExecute(con, sprintf(...))
  
  ## function to send a single query to the underlying connection
  sqlq = function(...) DBI::dbGetQuery(con, sprintf(...))
  
  sql("pragma page_size=4096") ## reasonably large page size; post 2011 hard drives have 4K sectors anyway
  
  tables = dplyr::src_tbls(src)
  
  isRecvDB = is.character(projRecv)
  
  if (! "meta" %in% tables) {
    if (missing(projRecv))
      stop("you must specify a project number or receiver serial number for a new database")
    sql("
create table meta (
key  character not null unique primary key, -- name of key for meta data
val  character                              -- character string giving meta data; might be in JSON format
)
");
if (isRecvDB)  {
  if (missing(deviceID) || ! isTRUE(is.numeric(deviceID))) {
    stop("must specify deviceID for new receiver database")
  }
  if (grepl("^SG", projRecv)) {
    type = "SENSORGNOME"
    model = substring(projRecv, 8, 11)
  } else {
    type = "Lotek"
    model = getLotekModel(projRecv)
  }
  sql("
insert into meta (key, val)
values
('dbType', 'receiver'),
('recvSerno', '%s'),
('recvType', '%s'),
('recvModel', '%s'),
('deviceID', '%d')
",
      projRecv,
      type,
      model,
      as.integer(deviceID))
} else if (is.numeric(projRecv)) {
  sql("
insert into meta (key, val)
values
('dbType', 'tag'),
('tagProject', %d)
",
      projRecv)
} else {
  stop("projRecv must be an integer motus project ID or a character receiver serial number")
}
  }
  
  if (! "gps" %in% tables) {
    sql("
create table gps (
gpsID   BIGINT PRIMARY KEY,                    -- id
batchID INTEGER NOT NULL REFERENCES batches, -- batch from which this fix came
ts      DOUBLE,                              -- system timestamp for this record
gpsts   DOUBLE,                              -- gps timestamp
lat     DOUBLE,                              -- latitude, decimal degrees
lon     DOUBLE,                              -- longitude, decimal degrees
alt     DOUBLE,                              -- altitude, metres
quality INTEGER
)");
    
    sql("create index gps_batchID on gps ( batchID )")
    sql("create index gps_ts on gps ( ts )")
    
    # Remove empty gps detections
    sql("DELETE FROM gps where lat = 0 and lon = 0 and alt = 0;")
    
  }
  
  if (! "batches" %in% tables) {
    sql("
CREATE TABLE batches (
    batchID INTEGER PRIMARY KEY,       -- unique identifier for this batch
    motusDeviceID INTEGER,                    -- motus ID of this receiver (NULL means not yet
                                              -- registered or not yet looked-up)  In a receiver
                                              -- database, this will be a constant column, but
                                              -- that way it has the same schema as in the master
                                              -- database.
    monoBN INT,                               -- boot number for this receiver; (NULL
                                              -- okay; e.g. Lotek)
    tsStart FLOAT(53),                        -- timestamp for start of period
                                              -- covered by batch; unix-style:
                                              -- seconds since 1 Jan 1970 GMT
    tsEnd FLOAT(53),                          -- timestamp for end of period
                                              -- covered by batch; unix-style:
                                              -- seconds since 1 Jan 1970 GMT
    numHits BIGINT,                           -- count of hits in this batch
    ts FLOAT(53),                             -- timestamp when this batch record was
                                              -- added; unix-style: seconds since 1
                                              -- Jan 1970 GMT
    motusUserID INT,                          -- user who uploaded the data leading to this batch
    motusProjectID INT,                       -- user-selected motus project ID for this batch
    motusJobID INT,                            -- job whose processing generated this batch
    source     TEXT                           -- tag source
);
")
  }
  
  
  if (! "runs" %in% tables) {
    sql("
CREATE TABLE runs (
    runID INTEGER PRIMARY KEY,                        -- identifier of run; unique for this receiver
    batchIDbegin INT NOT NULL,                        -- ID of batch this run begins in
    tsBegin FLOAT(53),                                -- timestamp of first detection in run
    tsEnd  FLOAT(53),                                 -- timestamp of last detection in run (so far)
    done TINYINT NOT NULL DEFAULT 0,                  -- is run finished? 0 if no, 1 if yes.
    motusTagID INT NOT NULL,                          -- ID for the tag detected; foreign key to Motus DB
                                                      -- table
    ant TEXT NOT NULL,                                -- antenna number (USB Hub port # for SG; antenna port
                                                      -- # for Lotek); 11 means Lotek master antenna 'A1+A2+A3+A4'
    len INT,                                          -- length of run within batch
    nodeNum TEXT,
    motusFilter INTEGER                               -- Probability of 'good'(1) vs. 'bad'(0) runs 
);

")
  }
  
  if (! "batchRuns" %in% tables) {
    sql("
CREATE TABLE batchRuns (
    batchID INTEGER NOT NULL,               -- identifier of batch
    runID INTEGER NOT NULL                  -- identifier of run
);
")
    sql("create index batchRuns_batchID on batchRuns ( batchID )")
    sql("create index batchRuns_runID on batchRuns ( runID )")
  }
  
  if (! "hits" %in% tables) {
    sql("
CREATE TABLE hits (
    hitID INTEGER PRIMARY KEY,                     -- unique ID of this hit
    runID INTEGER NOT NULL REFERENCES runs,        -- ID of run this hit belongs to
    batchID INTEGER NOT NULL REFERENCES batches,   -- ID of batch this hit belongs to
    ts FLOAT(53) NOT NULL,                         -- timestamp (centre of first pulse in detection);
                                                   -- unix-style: seconds since 1 Jan 1970 GMT
    sig FLOAT(24) NOT NULL,                        -- signal strength, in units appropriate to device;
                                                   -- e.g.; for SG/funcube; dB (max); for Lotek: raw
                                                   -- integer in range 0..255
    sigSD FLOAT(24),                               -- standard deviation of signal strength, in device
                                                   -- units (NULL okay; e.g. Lotek)
    noise FLOAT(24),                               -- noise level, in device units (NULL okay; e.g. Lotek)
    freq FLOAT(24),                                -- frequency offset, in kHz (NULL okay; e.g. Lotek)
    freqSD FLOAT(24),                              -- standard deviation of freq, in kHz (NULL okay;
                                                   -- e.g. Lotek)
    slop FLOAT(24),                                -- discrepancy of pulse timing, in msec (NULL okay;
                                                   -- e.g. Lotek)
    burstSlop FLOAT (24)                           -- discrepancy of burst timing, in msec (NULL okay;
                                                   -- e.g. Lotek)
);
")
    sql("CREATE INDEX IF NOT EXISTS hits_batchID_ts on hits(batchID, ts)")
    
  }
  
  ## table for keeping track of which batches we already have, *by* tagDepProjectID,
  ## and which hits we already have therein.
  ## A single batch might require several records in this table:  an ambiguous tag
  ## detection has (negative) tagDepProjectID, which corresponds to a unique set
  ## of projects which might own the tag detection.
  
  if (! "projBatch" %in% tables && ! isRecvDB) {
    sql("
CREATE TABLE projBatch (
    tagDepProjectID INTEGER NOT NULL, -- project ID
    batchID INTEGER NOT NULL,         -- unique identifier for batch
    maxHitID   INTEGER NOT NULL,      -- unique identifier for largest hit we have for this tagDepProjectID, batchID
    PRIMARY KEY (tagDepProjectID, batchID)
    );
")
    sql("
insert
   into projBatch
   select
      %d as tagDepProjectID,
      t1.batchID,
      max(t2.hitID)
   from
      batches as t1
      join hits as t2 on t2.batchID=t1.batchID
   group by
      t1.batchID
   order by
      t1.batchID
", projRecv)
  }
  
  if (! "tagAmbig" %in% tables) {
    sql("
CREATE TABLE tagAmbig (
    ambigID INTEGER PRIMARY KEY NOT NULL,  -- identifier of group of tags which are ambiguous (identical); will be negative
    masterAmbigID INTEGER,                 -- master ID of this ambiguity group, once different receivers have been combined
    motusTagID1 INT NOT NULL,              -- motus ID of tag in group (not null because there have to be at least 2)
    motusTagID2 INT NOT NULL,              -- motus ID of tag in group.(not null because there have to be at least 2)
    motusTagID3 INT,                       -- motus ID of tag in group.
    motusTagID4 INT,                       -- motus ID of tag in group.
    motusTagID5 INT,                       -- motus ID of tag in group.
    motusTagID6 INT,                       -- motus ID of tag in group.
    ambigProjectID INT                     -- negative ambiguity ID of deployment project. refers to key ambigProjectID in table projAmbig
);
")
  } else if (0 == nrow(sqlq("select * from sqlite_master where tbl_name='tagAmbig' and sql glob '*ambigProjectID*'"))) {
    ## older version of tagAmbig table, without the ambigProjectID column, so add it
    sql("ALTER TABLE tagAmbig ADD COLUMN ambigProjectID INTEGER")
  }
  
  if (! "projs" %in% tables) {
    sql("
CREATE TABLE projs (
   id INTEGER PRIMARY KEY NOT NULL,
   name TEXT,
   label TEXT,
   tagsPermissions INTEGER,
   sensorsPermissions INTEGER
);
")
  }
  if (! "tagDeps" %in% tables) {
    sql("
CREATE TABLE tagDeps (
   deployID INTEGER PRIMARY KEY,
   tagID INTEGER,
   projectID INTEGER,
   status TEXT,
   tsStart REAL,
   tsEnd REAL,
   deferSec INTEGER,
   speciesID INTEGER,
   bandNumber TEXT,
   markerNumber TEXT,
   markerType TEXT,
   latitude REAL,
   longitude REAL,
   elevation REAL,
   comments TEXT,
   id INTEGER,
   bi REAL,
   tsStartCode INTEGER,
   tsEndCode INTEGER,
   fullID TEXT
);
")
    sql("CREATE INDEX IF NOT EXISTS tagDeps_projectID on tagDeps(projectID)")
    sql("CREATE INDEX IF NOT EXISTS tagDeps_deployID on tagDeps(deployID)")
  }
  if (! "tagProps" %in% tables) {
    sql("
CREATE TABLE IF NOT EXISTS tagProps (
    tagID INTEGER NOT NULL,
    deployID INTEGER NOT NULL,
    propID INTEGER PRIMARY KEY,
    propName TEXT NOT NULL,
    propValue TEXT NULL
);
")
    sql("CREATE INDEX IF NOT EXISTS tagProps_deployID ON tagProps (
          deployID ASC
        );")
  }
  
  if (! "tags" %in% tables) {
    sql('
CREATE TABLE "tags" (
  "tagID" INTEGER PRIMARY KEY,
  "projectID" INTEGER,
  "mfgID" TEXT,
  "type" TEXT,
  "codeSet" TEXT,
  "manufacturer" TEXT,
  "model" TEXT,
  "lifeSpan" INTEGER,
  "nomFreq" REAL,
  "offsetFreq" REAL,
  "bi" REAL,
  "pulseLen" REAL
);
')
    sql("CREATE INDEX IF NOT EXISTS tags_projectID on tags(projectID)")
  }
  
  if (! "recvDeps" %in% tables) {
    sql("
CREATE TABLE recvDeps (
   deployID INTEGER PRIMARY KEY,
   serno TEXT,
   receiverType TEXT,
   deviceID INTEGER,
   macAddress TEXT,
   status TEXT,
   name TEXT,
   fixtureType TEXT,
   latitude REAL,
   longitude REAL,
   isMobile INTEGER,
   tsStart REAL,
   tsEnd REAL,
   projectID INTEGER,
   elevation REAL,
   siteName TEXT,
   utcOffset INTEGER
)
")
sql("CREATE INDEX IF NOT EXISTS recvDeps_serno on recvDeps(serno)")
sql("CREATE INDEX IF NOT EXISTS recvDeps_deviceID on recvDeps(deviceID)")
sql("CREATE INDEX IF NOT EXISTS recvDeps_projectID on recvDeps(projectID)")
  }
  
  if (! "recvs" %in% tables) {
    sql("
CREATE TABLE recvs (
   deviceID INTEGER PRIMARY KEY NOT NULL,
   serno TEXT
)
")
sql("
INSERT OR IGNORE
   INTO recvs
SELECT
   deviceID,
   serno
FROM
   recvDeps
")
  }
  
  if (! "antDeps" %in% tables) {
    sql("
CREATE TABLE antDeps (
   deployID INTEGER,
   port TEXT,
   antennaType TEXT,
   bearing REAL,
   heightMeters REAL,
   cableLengthMeters REAL,
   cableType TEXT,
   mountDistanceMeters REAL,
   mountBearing REAL,
   polarization2 REAL,
   polarization1 REAL,
   primary key(deployID, port)
);
")
    sql("CREATE INDEX IF NOT EXISTS antDeps_deployID on antDeps(deployID)")
    sql("CREATE INDEX IF NOT EXISTS antDeps_port on antDeps(port)")
  }
  
  if (! "species" %in% tables) {
    sql("
CREATE TABLE species (
   id INTEGER PRIMARY KEY NOT NULL,
   english TEXT,
   french TEXT,
   scientific TEXT,
   \"group\" TEXT,
   \"sort\" INTEGER
);
");
  }
  if (! "projAmbig" %in% tables) {
    sql("
CREATE TABLE  projAmbig (
   ambigProjectID INTEGER PRIMARY KEY NOT NULL,  -- identifies a set of projects which a tag detection *could* belong to; negative
   projectID1 INT NOT NULL,              -- projectID of project in set
   projectID2 INT,                       -- projectID of project in set
   projectID3 INT,                       -- projectID of project in set
   projectID4 INT,                       -- projectID of project in set
   projectID5 INT,                       -- projectID of project in set
   projectID6 INT                        -- projectID of project in set
);
")
    
  }
  
  if (! "pulseCounts" %in% tables && isRecvDB) {
    sql("
CREATE TABLE pulseCounts (
   batchID INTEGER NOT NULL,             -- batchID that generated this record
   ant TEXT NOT NULL,                    -- antenna
   hourBin INTEGER,                      -- hour bin for this count; this is round(ts/3600)
   count   INTEGER,                      -- number of pulses for given pcode in this file
   PRIMARY KEY (batchID, ant, hourBin)   -- a single count for each batchID, antenna, and hourBin
);
")
  }
  if (! "clarified" %in% tables) {
    sql("
CREATE TABLE clarified (
   ambigID INTEGER,
   tagID INTEGER,
   tsStart REAL,
   tsEnd REAL)
")
    sql("
CREATE INDEX IF NOT EXISTS clarified_ambigID_tsStart ON clarified(ambigID, tsStart)
")
  }
  if (! "filters" %in% tables) {
    sql("
CREATE TABLE filters (
   filterID INTEGER PRIMARY KEY,            -- locally unique filterID
   userLogin TEXT NOT NULL,                 -- motus login of the user who created the filter
   filterName TEXT NOT NULL,                -- short name used to refer to the filter by the user
   motusProjID INTEGER NOT NULL,            -- optional project ID when the filter needs to be shared with other users of a project
   descr TEXT,                              -- longer description of what the filter contains
   lastModified TEXT NOT NULL               -- date when the filter was last modified
);
");
    sql("
CREATE UNIQUE INDEX IF NOT EXISTS filters_filterName_motusProjID ON filters (
  filterName ASC,
  motusProjID ASC);
")
    
  }
  
  if (! "runsFilters" %in% tables) {
    sql("
CREATE TABLE runsFilters (
   filterID INTEGER NOT NULL,               -- locally unique filterID
   runID INTEGER NOT NULL,                  -- unique ID of the run record to which the filter applies
   motusTagID INTEGER NOT NULL,             -- unique ID of the Motus tag. Should match the actual motusTagID, not the negative ambigID in the case of ambiguous runs.
   probability REAL NOT NULL,               -- probability (normally between 0 and 1) attached to the run record
   PRIMARY KEY(filterID,runID,motusTagID)
);
");
    sql("
CREATE INDEX IF NOT EXISTS runsFilters_filterID_runID_motusTagID ON runsFilters (
  filterID ASC, 
  runID ASC, 
  motusTagID ASC,
  probability ASC);
")
    
  }
  
  if (! "activity" %in% tables) {
    sql("CREATE TABLE IF NOT EXISTS activity (
      batchID INTEGER,
      motusDeviceID INTEGER,
      ant TEXT,
      year INTEGER,
      month INTEGER,
      day INTEGER,
      hourBin INTEGER,
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
      UNIQUE(batchID, ant, hourBin),
      PRIMARY KEY (batchID, ant, hourBin));")
  }

  if(! "admInfo" %in% tables) {
    sql("CREATE TABLE IF NOT EXISTS admInfo (db_version INTEGER, data_version TEXT);")
    sql("INSERT INTO admInfo (db_version, data_version) values ('1980-01-01', %d);",
        motus_vars$dataVersion)
  }
  
  if(! "nodeData" %in% tables) {
    sql("CREATE TABLE IF NOT EXISTS nodeData (
      id BIGINT PRIMARY KEY NOT NULL,
      batchID INTEGER NOT NULL,
      ts FLOAT NOT NULL,
      nodeNum TEXT NOT NULL,
      ant TEXT NOT NULL,
      sig FLOAT(24),
      battery FLOAT,
      temperature FLOAT);")
  }
  
  if(! "nodeDeps" %in% tables) {
    sql("CREATE TABLE IF NOT EXISTS nodeDeps (
      deployID INTEGER NOT NULL,
      nodeDeployID BIGINT PRIMARY KEY NOT NULL, 
      latitude  FLOAT, 
      longitude FLOAT, 
      tsStart FLOAT NOT NULL, 
      tsEnd FLOAT NOT NULL);")
  }

  rv = makeAllambigsView(src)
  rv = makeAlltagsView(src)
  rv = updateMotusDb(rv, src)
  return(rv)
}
