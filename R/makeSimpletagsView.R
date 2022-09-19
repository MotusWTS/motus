#' Create a simple view of tag detections
#'
#' Creates a virtual table (really a 'view') in a motus database that
#' links each tag detection to basic metadata for the tag and
#' receiver.  This is a much "narrower" view than the 'alltags' view
#' created by `makeAlltagsView()`
#'
#' @param src SQLite connection
#' @param name character scalar; name for the virtual table.
#'     Default: 'simpletags'.
#'
#' @return a dplyr::tbl which refers to the newly-created virtual table.
#' 
#' @noRd
#'

makeSimpletagsView <- function(src, name = "simpletags") {
    query <- glue::glue("CREATE VIEW {name} AS
SELECT
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
   t2.len AS runLen,
   t3.motusDeviceID,
   t3.monoBN,
   t4.nomFreq AS tagFreq,
   t9.id AS tagProjID,
   t9.label AS tagProj,
   t5.speciesID,
   t6c.serno AS recv,
   t6.name AS site,
   t6.latitude AS lat,
   t6.longitude AS long,
   t6.elevation AS alt,
   t10.id AS recvProjID,
   t10.label AS recvProj
FROM
   hits AS t1
   LEFT JOIN runs     AS t2  ON t1.runID    = t2.runID
   LEFT JOIN batches  AS t3  ON t3.batchID  = t1.batchID
   LEFT JOIN tags     AS t4  ON t4.tagID    = t2.motusTagID
   LEFT JOIN tagDeps  AS t5  ON t5.tagID    = t2.motusTagID
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
   LEFT JOIN recvs AS t6c ON t6c.deviceID = t3.motusDeviceID
   LEFT JOIN recvDeps AS t6 ON t6.deviceID = t3.motusDeviceID
                            AND t6.tsStart =
                               (SELECT
                                   max(t6b.tsStart)
                                FROM
                                   recvDeps AS t6b
                                WHERE
                                   t6b.deviceID = t3.motusDeviceID
                                   AND t6b.tsStart <= t1.ts
                                   AND (t6b.tsEnd IS NULL OR t6b.tsEnd >= t1.ts)
                               )
   LEFT JOIN projs AS t9  ON t9.id  = t5.projectID
   LEFT JOIN projs AS t10 ON t10.id = t6.projectID
")
    
    DBI_Execute(src, "DROP VIEW IF EXISTS {name}")
    DBI_Execute(src, query)
    dplyr::tbl(src, name)
}
