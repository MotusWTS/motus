#' create a view of tag detections with basic metadata
#'
#' Creates a virtual table (really a 'view') in a motus database that
#' links each tag detection to basic metadata for the tag and
#' receiver.  This is a much "narrower" view than the 'alltags' view
#' created by \code{makeAlltagsView()}
#'
#' @param db dplyr src_sqlite to detections database
#'
#' @param name character scalar; name for the virtual table.
#'     Default: 'simpletags'.
#'
#' @return a dplyr::tbl which refers to the newly-created virtual table.
#' The columns in the virtual table are:
#' \itemize{
#'    \item hitID numeric; unique motus identifier for this detection
#'    \item motusTagID integer; unique motus identifier for the tag detected
#'    \item mfgID numeric; manufacturer tag ID
#'    \item fullID character; full ID of tag, in form "PROJ#MFGID:BI@FREQ"
#'    \item ts numeric; timestamp of detection; seconds since 1 Jan 1970 00:00:00 GMT
#'    \item sig numeric; relative signal strength (dB max)
#'    \item sigSD numeric; standard deviation of signal strength (dB)
#'    \item noise numeric; relative noise level (dB max)
#'    \item freq numeric; offset frequency (kHz)
#'    \item freqSD numeric; standard deviation of offset frequency
#'    \item slop numeric; total absolute deviation from true tag pulse spacing (milliseconds)
#'    \item burstSlop numeric; deviation from registered tag burst interval (seconds)
#'    \item runID numeric; unique motus ID for run of detections including this one
#'    \item ant character; antenna identifier (usually a small integer, for USB port)
#'    \item runLen integer; number of detections in this run
#'    \item motusDeviceID integer; unique motus ID for receiver that detected tag
#'    \item monoBN integer; boot number
#'    \item tagFreq numeric; nominal tag frequency (MHz)
#'    \item tagProjID integer; unique motus identifier for project that deployed tag
#'    \item tagProj character; short name of motus project that deployed tag
#'    \item speciesID integer; unique species identifier (from motus.org)
#'    \item recv character; receiver serial number
#'    \item site character; receiver site name
#'    \item lat numeric; latitude in decimal degrees North (so negative is South)
#'    \item long numeric; longitude in decimal degrees East (so negative is West)
#'    \item alt numeric; altitude in metres above sea level
#'    \item recvProjID; integer unique ID of motus project that deployed receiver
#'    \item recvProj; character; short name of motus project that deployed receiver
#' }
#' @noRd
#'

makeSimpletagsView = function(db, name="simpletags") {
    query = paste0("create view ", name, " as
select
   t1.hitID,
   t2.motusTagID,
   t4.mfgID,
   t5.fullID,
   t1.ts,
   t1.sig,
   t1.sigSD,
   t1.noise,
   t1.freq,
   t1.freqSD,
   t1.slop,
   t1.burstSlop,
   t1.runID,
   t2.ant,
   t2.len as runLen,
   t3.motusDeviceID,
   t3.monoBN,
   t4.nomFreq as tagFreq,
   t9.id as tagProjID,
   t9.label as tagProj,
   t5.speciesID,
   t6c.serno as recv,
   t6.name as site,
   t6.latitude as lat,
   t6.longitude as long,
   t6.elevation as alt,
   t10.id as recvProjID,
   t10.label as recvProj
from
   hits as t1
   left join runs     as t2  on t1.runID    = t2.runID
   left join batches  as t3  on t3.batchID  = t1.batchID
   left join tags     as t4  on t4.tagID    = t2.motusTagID
   left join tagDeps  as t5  on t5.tagID    = t2.motusTagID
                             and t5.tsStart =
                                (select
                                    max(t5b.tsStart)
                                 from
                                    tagDeps AS t5b
                                 where
                                    t5b.tagID = t2.motusTagID
                                    and t5b.tsStart <= t1.ts
                                    and (t5b.tsEnd is null or t5b.tsEnd >= t1.ts)
                                )
   left join recvs as t6c on t6c.deviceID = t3.motusDeviceID
   left join recvDeps as t6 on t6.deviceID = t3.motusDeviceID
                            and t6.tsStart =
                               (select
                                   max(t6b.tsStart)
                                from
                                   recvDeps AS t6b
                                where
                                   t6b.deviceID = t3.motusDeviceID
                                   and t6b.tsStart <= t1.ts
                                   and (t6b.tsEnd is null or t6b.tsEnd >= t1.ts)
                               )
   left join projs as t9  on t9.id  = t5.projectID
   left join projs as t10 on t10.id = t6.projectID
")
    DBI::dbExecute(db$con, paste0("DROP VIEW IF EXISTS ", name))
    DBI::dbExecute(db$con, query)
    return(dplyr::tbl(db, name))
}
