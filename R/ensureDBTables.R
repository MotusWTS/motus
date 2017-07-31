#' make sure a tag or receiver database has the required tables
#'
#' @param src dplyr sqlite src, as returned by \code{dplyr::src_sqlite()}
#'
#' @param projRecv integer scalar motus project ID number *or*
#'     character scalar receiver serial number; must be specified if
#' \code{src} does not already contain a table named \code{meta}.
#'
#' @param deviceID integer scalar motus deviceID; must be specified
#' when this is a new receiver database.
#'
#' @return returns a dplyr::tbl representing the alltags virtual table
#' which is created in \code{src}.
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

    sql("pragma page_size=4096") ## reasonably large page size; post 2011 hard drives have 4K sectors anyway

    tables = src_tbls(src)

    if (all(dbTableNames %in% tables))
        return()

    if (! "meta" %in% tables) {
        if (missing(projRecv))
            stop("you must specify a project number or receiver serial number for a new database")
        sql("
create table meta (
key  character not null unique primary key, -- name of key for meta data
val  character                              -- character string giving meta data; might be in JSON format
)
");
        if (is.character(projRecv))  {
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
batchID INTEGER NOT NULL REFERENCES batches, -- batch from which this fix came
ts      DOUBLE,                              -- system timestamp for this record
gpsts   DOUBLE,                              -- gps timestamp
lat     DOUBLE,                              -- latitude, decimal degrees
lon     DOUBLE,                              -- longitude, decimal degrees
alt     DOUBLE,                              -- altitude, metres
PRIMARY KEY (batchID, ts)
)");

        sql("create index gps_batchID on gps ( batchID )")
        sql("create index gps_ts on gps ( ts )")

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
    motusJobID INT                            -- job whose processing generated this batch
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
    ant TINYINT NOT NULL,                             -- antenna number (USB Hub port # for SG; antenna port
                                                      -- # for Lotek); 11 means Lotek master antenna 'A1+A2+A3+A4'
    len INT                                           -- length of run within batch
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
    motusTagID6 INT                        -- motus ID of tag in group.
);
")
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
   elevation REAL
);
")
        sql("CREATE INDEX IF NOT EXISTS recvDeps_serno on recvDeps(serno)")
        sql("CREATE INDEX IF NOT EXISTS recvDeps_deviceID on recvDeps(deviceID)")
        sql("CREATE INDEX IF NOT EXISTS recvDeps_projectID on recvDeps(projectID)")
    }

    if (! "antDeps" %in% tables) {
        sql("
CREATE TABLE antDeps (
   deployID INTEGER,
   port INTEGER,
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
    makeAlltagsView(src)
}

## list of tables needed in the receiver database

dbTableNames = c("alltags", "meta", "batches", "runs", "batchRuns", "hits", "gps", "tagAmbig", "projs", "tags", "tagDeps", "recvDeps", "antDeps", "species")
