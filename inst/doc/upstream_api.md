# The motusClient R package upstream API #

The motusClient R package maintains your copy of a tag detection
database.  The database is built from data provided by a server,
typically at motus.org   This document describes the API calls required
by the motusClient package; i.e. what requests must a server respond to if
it is to work with this package.

### Quick Links to API Entries by Topic ###

- **[API info](#api-info)**
- **[authentication](#authenticate-user)**
- **size of update**: [for tag project](#size-of-update-for-tag-project); [for receiver](#size-of-update-for-receiver)
- **receivers:**  [list by project](#receivers-for-project); [lookup deviceID](#deviceid-for-receiver)
- **batches:** [for tag project](#batches-for-tag-project); [for receiver](#batches-for-receiver)
- **runs:** [for tag project](#runs-for-tag-project); [for receiver](#runs-for-receiver)
- **hits:** [for tag project](#hits-for-tag-project); [for receiver](#hits-for-receiver)
- **gps:** [for tag project](#gps-for-tag-project); [for receiver](#gps-for-receiver)
- **pulse counts:** [for_receiver](#pulse-counts-for-receiver)
- **metadata:** [for tags](#metadata-for-tags); [for receivers](#metadata-for-receivers)
- **ambiguities:** [among tags](#tags-for-ambiguities); [among projects](#project-ambiguities-for-tag-project)

## API summary ##

### Request ###
 - requests are sent by the HTTP POST method
 - the request has header `Content-Type: application/x-www-form-urlencoded`
 - can have an optional header `Accept-Encoding: gzip` in which case the reply
   will be gzip-compressed, rather then bzip2-compressed (see below)
 - the POST data has a single item called `json`, which is a JSON-encoded object.
 - the fields of `json` are the parameters listed for each API entrypoint below.
 - most requests require an `authToken` value, which can be obtained by a call
   to `authenticate_user`
 - if a request indicates that a parameter should be an array, then
   a scalar of the same type can be provided instead, and is treated as an array of length 1.
   i.e. the API doesn't distinguish between `"par":X` and `"par":[X]` if `X` is a double, integer,
   boolean or string

### Reply ###
 - is a JSON-encoded object: header `Content-Type = application/json`
 - is bzip2-compressed: header `Content-Encoding = bzip2`.  To support browsers and other
   contexts without native bzip2 decompression, if the request had a
   header called `Accept-Encoding` that includes the string "gzip", then the
   reply is gzip-compressed, with header `Content-Encoding: gzip`.
 - most returned objects have fields which are arrays of
   equal length, which is the natural JSON encoding of an R data.frame
 - errors are indicated by including a field called `error` in the reply; other
   fields might be present, giving additional information.  If no field `error`
   is present, the request succeeded.
 - requests return a (fixed) maximum number of rows.  If a reply has
   fewer than the maximum number of rows, there are no further data
   for the given query; i.e. the next `paging` call to the same API
   would return 0 rows.  The maximum number of rows can be obtained by
   calling `api_info`

Examples are given for each call using the command-line
client [curl](https://curl.haxx.se/download.html) with quoting
appropriate for the Bash shell.  These examples return the raw
bzip2-compressed data. To view the response, redirect the output of
curl into a file and use [7zip](http://7-zip.org) to decompress it
(for example), or add ` | bunzip2 -cd ` to the end of the command in
Bash.

The server is at [https://sgdata.motus.org](https://sgdata.motus.org) and the URL prefix is "/data/custom/".

## API calls ##

### api info ###

   api_info (authToken)

   - return an object with these items:

      - maxRows: integer, maximum number of rows returned by a query

      e.g.
      curl https://sgdata.motus.org/data/custom/api_info


### authenticate user ###

   authenticate_user (user, password)

      - user: username
      - password: password (in cleartext)

      e.g.
      curl --data-urlencode json='{"user":"someone","password":"bigsecret"}' https://sgdata.motus.org/data/custom/authenticate_user

   - returns an object with these fields:
      - authToken: string; 264 random bits, base64-encoded
      - expiry: double timestamp of expiry for token
      - userID: integer; motus ID for user
      - projects: array of integer; project #s user is allowed to request tag detections for
      - receivers: array of string; serial #s of receivers user is allowed to request tag detections for

   or

   - a list with this item:
      - error: "authentication with motus failed"

### Notes ###

1. The `authToken` returned by this API must be included in most other API calls.

2. Authorization is by project: if a user has permission for a
project, then that user can see:

   - all detections from receivers deployed by that project

   - all detections of tags deployed by that project

If an API call does not find any data for which the user is
authorized, it will return a json object of the usual structure,
except that arrays will have length zero.  This represents an R
data.frame with the correct column names but zero rows.

The API doesn't currently provide a way to tell whether there are additional data
which would be returned for a given call if the user had authorization for more
projects.

"Ownership" of detections follows these assumptions:

- tag runs nest within tag deployments:  either all or none of the detections of a tag
run belong to a given tag deployment; i.e. we assume the tag is deactivated
for at least ~ 20 minutes between deployments under **different** projects.

- batches nest within receiver deployments:  either all or none of the detections in a
batch belong to a given receiver deployment; i.e. we assume the receiver is
rebooted at least once between deployments under **different** projects.

These assumptions allow for simpler, more efficient database queries.

### deviceID for receiver ###

   deviceID_for_receiver (serno, authToken)

       - serno: array of string; receiver serial number(s)

      e.g.
      curl --data-urlencode json='{"serno":"SG-1234BBBK5678","authToken":"XXX"}' https://sgdata.motus.org/data/custom/deviceID_for_receiver

   - return a list of receiver device IDs for the given serial numbers

   - fields in the returned object are arrays:
      - serno: string; serial number, as specified
      - deviceID: integer; motus device ID, or NA where the serial number was not found

### receivers for project ###

   receivers_for_project (projectID, authToken)

       - projectID: integer; project ID

      e.g.
      curl --data-urlencode json='{"projectID":123,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/receivers_for_project

   - return a list of receiver deployments belonging to project `projectID`

   - fields in the returned object are arrays:
      - serno: string; serial number; e.g. SG-1234BBBK9876, Lotek-149
      - receiverType: string; "LOTEK" or "SENSORGNOME"
      - deviceID: integer; motus device ID
      - status: string;
      - deployID: integer; motus device deployment ID
      - name: string; short name for this deployment; typically a site name
      - fixtureType: string; e.g. "PopTower"
      - latitude: double; decimal degrees North (at start of deployment if mobile)
      - longitude: double; decimal degrees East (at start of deployment if mobile)
      - isMobile logical; is this a mobile deployment
      - tsStart: double; unix timestamp of start of deployment
      - tsEnd: double; unix timestamp of end of deployment, or null if still deployed
      - projectID: integer; motus project ID owning deployment
      - elevation: double; metres above sea level

### batches for tag project ###

   batches_for_tag_project (projectID, batchID, authToken)

       - projectID: integer; project ID
       - batchID: integer; largest batchID we already have for this project
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":0, "authToken":"XXX"}' https://sgdata.motus.org/data/custom/batches_for_tag_project

   - return a list of all batches with detections of tags in project `projectID`,
     where the batchID is > `batchID`

   - fields in the returned object are arrays:
      - batchID
      - deviceID
      - monoBN
      - tsBegin
      - tsEnd
      - numHits
      - ts

Paging for this query is achieved by using the largest returned value of `batchID`
as `batchID` on subsequent calls.  When there are no further batches, the API
returns an empty list.

### batches for receiver ###

   batches_for_receiver (deviceID, batchID, authToken)

       - deviceID: integer; motus device ID, e.g. as returned by receivers_for_project
       - batchID: integer; largest batchID we already have for this project
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":0, "authToken":"XXX"}' https://sgdata.motus.org/data/custom/batches_for_receiver

   - return a list of all batches from deployments of the device by
     project projectID, where the batchID is > `batchID`

   - the returned object has these array fields:
      - batchID: integer;
      - deviceID: integer; motus device ID
      - monoBN: integer; corrected boot count for device (where available)
      - tsBegin: double; unix timestamp (seconds since 1 Jan 1970 GMT) for start of raw data processed in this batch
      - tsEnd: double; unix timestamp for end of raw data processed in this batch
      - numHits: integer; count of detections on all antennas in this batch
      - ts: double; unix timestamp at which processing of this batch completed

Paging for this query is achieved by using the largest returned value of `batchID`
as `batchID` on subsequent calls.  When there are no further batches, the API
returns an empty list.

### batches for all ###

   batches_for_all (batchID, authToken) - administrative users only

       - batchID: integer; largest batchID we already have
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"batchID":0, "authToken":"XXX"}' https://sgdata.motus.org/data/custom/batches_for_all

   - return a list of all batches from any receiver, where the batchID is > `batchID`

   - fields in the returned object are arrays:
      - batchID
      - deviceID
      - monoBN
      - tsBegin
      - tsEnd
      - numHits
      - ts

Paging for this query is achieved by using the largest returned value of `batchID`
as `batchID` on subsequent calls.  When there are no further batches, the API
returns an empty list.

This call is intended only for users who are building a database of *all*
detections.  Currently, that means only administrative users.

### runs for tag project ###

   runs_for_tag_project (projectID, batchID, runID, authToken)

       - projectID: integer; project ID
       - batchID: integer; batch ID
       - runID: integer; largest run ID we *already* have from this batch and tag project
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":111,"runID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/runs_for_tag_project

   - return a list of all runs of a tag in project `projectID`, from batch
     `batchID` and with run ID > `runID`

   - fields in the returned object are arrays:
      - runID
      - batchIDbegin
      - tsBegin
      - tsEnd
      - done
      - motusTagID
      - ant
      - len

Paging for this query is achieved by using the last returned value of `runID`
as `runID` on subsequent calls.  When there are no further runs, the API
returns an empty list.

### runs for receiver ###

   runs_for_receiver (batchID, runID, authToken)

       - batchID: integer; batch ID
       - runID: integer; largest runID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":111,"runID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/runs_for_receiver

   - return a list of all runs from batch `batchID` with run ID > `runID`

   - fields in the returned object are arrays:
      - runID
      - batchIDbegin
      - tsBegin
      - tsEnd
      - done
      - motusTagID
      - ant
      - len

Paging for this query is achieved by using the last returned value of `runID`
as `runID` on subsequent calls.  When there are no further runs, the API
returns an empty list.

For regular users, this only returns runs if the user has permission for
the project which owns the receiver deployment covering this batch.

For admin users, *all* runs are returned, regardless of batch ownership
(or lack thereof).

### hits for tag project ###

   hits_for_tag_project (projectID, batchID, hitID, authToken)

       - projectID: integer; project ID
       - batchID: integer; batchID
       - hitID: integer; largest hitID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":111,"hitID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/hits_for_tag_project

   - return a list of all hits on tags in project `projectID` which are in batch `batchID`,
     and whose hit ID is > `hitID`

   - fields in the returned object are arrays:
      - hitID
      - runID
      - batchID
      - ts
      - sig
      - sigSD
      - noise
      - freq
      - freqSD
      - slop
      - burstSlop

Paging for this query is achieved by using the last returned value of `hitID`
as `hitID` on subsequent calls.  When there are no further hits, the API
returns an empty list.

### hits for receiver ###

   hits_for_receiver (batchID, hitID, authToken)

       - batchID: integer; batchID
       - hitID: integer; largest hitID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"batchID":111,"hitID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/hits_for_receiver

   - return a list of all hits in batch `batchID` whose hit ID is > `hitID`

   - fields in the returned object are arrays:
      - hitID
      - runID
      - batchID
      - ts
      - sig
      - sigSD
      - noise
      - freq
      - freqSD
      - slop
      - burstSlop

Paging for this query is achieved by using the last returned value of `hitID`
as `hitID` on subsequent calls.  When there are no further hits, the API
returns an empty list.

For regular users, this only returns hits if the user has permission for
the project which owns the receiver deployment covering this batch.

For admin users, *all* hits are returned, regardless of batch ownership
(or lack thereof).

### gps for tag project ###

   gps_for_tag_project (projectID, batchID, ts, authToken)

       - projectID: integer; project ID of tags
       - batchID: integer; batchID where tags from projectID were detected
       - ts: largest gps timestamp we *already* have for this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":111,"ts":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/gps_for_tag_project

   - return all GPS fixes from batch `batchID` which are later than
     timestamp ts and "relevant to" detections of a tag deployment
     from project `projectID`.  This is given a permissive
     interpretation: all GPS fixes from 1 hour before the first
     detection of a project tag to 1 hour after the last detection of
     a project tag in the given batch are returned.  This might return
     GPS fixes for long periods where no tags from the project were
     detected, if a batch has a few early and a few late detections of
     the project's tags.

   - fields in the returned object are arrays:
     - ts
     - batchID (optional; this is just batchID)
     - lat
     - lon
     - alt

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further GPS fixes, the API
returns an empty list.

### gps for receiver ###

   gps_for_receiver (batchID, ts, authToken)

       - batchID: integer; batchID
       - ts: largest gps timestamp we *already* have for this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"batchID":111,"ts":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/gps_for_receiver

   - return all GPS fixes from batch batchID which are later than timestamp ts

   - fields in the returned object are arrays:
     - ts
     - batchID (optional; this is just batchID)
     - lat
     - lon
     - alt

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further GPS fixes, the API
returns an empty list.

For regular users, this only returns gps records if the user has permission for
the project which owns the receiver deployment covering this batch.

For admin users, *all* gps records are returned, regardless of batch ownership
(or lack thereof).

### metadata for tags ###

    metadata for tags (motusTagIDs, authToken)

       - motusTagIDs: integer array; motus tag IDs; tag metadata will
         only be returned for tag deployments whose project has indicated
         their metadata are public, or tags deployments by one of the
         projects the user has permissions to.
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"motusTagIDs":[12345,12346,12347],"authToken":"XXX"}' https://sgdata.motus.org/data/custom/metadata_for_tags

   - return an object with these fields:

      - tags; a object with these array fields:
         - tagID: integer; tag ID
         - projectID: integer; motus ID of project which *registered* tag
         - mfgID; string; manufacturer tag ID
         - type; string;  "ID" or "BEEPER"
         - codeSet; string; e.g. "Lotek3", "Lotek4"
         - manufacturer; string; e.g. "Lotek"
         - model; string; e.g. "NTQB-3-1"
         - lifeSpan: integer; estimated tag lifeSpan, in days
         - nomFreq: double; nominal frequency of tag, in MHz
         - offsetFreq: double; estimated offset frequency of tag, in kHz
         - bi: double; burst interval or period of tag, in seconds
         - pulseLen: double; length of tag pulses, in ms (not applicable to all tags)

      - tagDeps; a object with these array fields:
         - tagID: integer; motus tagID
         - deployID: integer; tag deployment ID (internal to motus)
         - projectID: integer; motus ID of project which *deployed* tag
         - tsStart: double; timestamp of start of deployment
         - tsEnd: double; timestamp of end of deployment
         - deferSec: integer; deferred activation period, in seconds (0 for most tags).
         - speciesID: integer; motus species ID code
         - markerType; string; type of marker on organism; e.g. leg band
         - markerNumber; string; details of marker; e.g. leg band code
         - latitude: double; deployment location, degrees N (negative is S)
         - longitude: double; deployment location, degrees E (negative is W)
         - elevation: double; deployment location, metres ASL
         - comments; string; possibly JSON-formatted list of additional metadata

      - species; a object with these array fields:
         - id: integer; species ID,
         - english; string; English species name
         - french; string; French species name
         - scientific; string; scientific species name
         - group; string; higher-level taxon

      - projs; a object with these array fields:
         - id: integer; motus project id
         - name; string; full name of motus project
         - label; string; short label for motus project; e.g. for use in plots
);

### metadata for receivers ###

    metadata for receivers (deviceIDs, authToken)

       - deviceID: integer; device ID; receiver metadata will only be
         returned for receivers whose project has indicated their
         metadata are public, or receivers in one of the projects the
         user has permissions to.
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"deviceIDs":[123,124,125],"authToken":"XXX"}' https://sgdata.motus.org/data/custom/metadata_for_receivers

   - return an object with these fields:

      - recvDeps; a object with these array fields:
         - deployID: integer; deployment ID (internal to motus, but links to antDeps)
         - projectID: integer; ID of project that deployed the receiver
         - serno; string; serial number, e.g. "SG-1214BBBK3999", "Lotek-8681"
         - receiverType; string; "SENSORGNOME" or "LOTEK"
         - deviceID: integer; device ID (internal to motus)
         - status; string; deployment status
         - name; string; typically a site name
         - fixtureType; string; what is the receiver mounted on?
         - latitude: double; (initial) location, degrees North
         - longitude: double; (initial) location, degrees East
         - elevation: double; (initial) location, metres ASL
         - isMobile: integer; non-zero means a mobile deployment
         - tsStart: double; timestamp of deployment start
         - tsEnd: double; timestamp of deployment end, or NA if ongoing

      - antDeps; a object with these array fields:
         - deployID: integer, links to deployID in recvDeps table
         - port: integer, which receiver port (USB for SGs, BNC for
           Lotek) the antenna is connected to
         - antennaType; string; e.g. "Yagi-5", "omni"
         - bearing: double; compass angle at which antenna is pointing; degrees clockwise from
           magnetic north
         - heightMeters: double; height of main antenna element above ground
         - cableLengthMeters: double; length of coaxial cable from antenna to receiver, in metres
         - cableType: string; type of cable; e.g. "RG-58"
         - mountDistanceMeters: double; distance of mounting point from receiver, in metres
         - mountBearing: double; compass angle from receiver to antenna mount; degrees clockwise from
           magnetic north
         - polarization2: double; angle giving tilt from "normal" position, in degrees
         - polarization1: double; angle giving rotation of antenna about own axis, in degrees.

      - projs; a object with these array fields:
         - id: integer; motus project id
         - name; string; full name of motus project
         - label; string; short label for motus project; e.g. for use in plots

### tags for ambiguities ###

   tags for ambiguities (ambigIDs, authToken)

       - ambigIDs: integer; tag ambiguity IDs; this is an array of negative
         integers, each representing 2 to 6 tags for which detections are
         indistinguishable over some period of time; i.e. a detection of
         the given ambigID could represent any of the motus tagIDs.  (6 is
         an implementation limit, not a conceptual one.)
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"ambigIDs":[-3,-4,-5],"authToken":"XXX"}' https://sgdata.motus.org/data/custom/tags_for_ambiguities

   - return an object with these arrays:
      - ambigID; negative integer; tag ambiguity ID
      - motusTagID1; positive integer; motus tag ID
      - motusTagID2; positive integer; motus tag ID
      - motusTagID3; positive integer; motus tag ID or null
      - motusTagID4; positive integer; motus tag ID or null
      - motusTagID5; positive integer; motus tag ID or null
      - motusTagID6; positive integer; motus tag ID or null
      - ambigProjectID; negative integer; ambiguous project ID

      i.e. return what real tags each ambiguityID represents.
      If `motusTagIDM[i]` is null, then `motusTagIDN[i]` is also null for
      `M < N <= 6`; i.e. non-null values precede null values
      for each ambiguity.


### size of update for tag project ###

   size_of_update_for_tag_project (projectID, batchID, authToken)

       - projectID: integer; project ID
       - batchID: integer; ID of largest batch client already has

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":15538,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/size_of_update_for_tag_project

   - return a list with these scalar items:
      - numBatches
      - numRuns
      - numHits
      - numGPS
      - numBytes: estimated uncompressed size of data transfer

### size of update for receiver ###

   size_of_update_for_receiver (deviceID, batchID, authToken)

       - deviceID: integer; motus device ID
       - batchID: integer; ID of largest batch client already has

      e.g.
      curl --data-urlencode json='{"deviceID":221,"batchID":15538,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/size_of_update_for_receiver

   - return a list with these scalar items:
      - numBatches
      - numRuns
      - numHits
      - numGPS
      - numBytes: estimated uncompressed size of data transfer

For regular users, this only counts items where the user has permission for
the project which owns the receiver deployment covering the batch.

For admin users, *all* items are counted, regardless of batch ownership
(or lack thereof).

### project ambiguities for tag project ###

   project_ambiguities_for_tag_project (projectID)

       - projectID: integer; projectID

      e.g.
      curl --data-urlencode json='{"projectID":123,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/project_ambiguities_for_tag_project

   - return a list of project ambiguities for project `projectID`. A
     *project ambiguity* is the set of projectIDs associated with an
     ambiguous tag detection: if a detection could be either tag T1
     from project P1, or tag T2 from project P2, then we assign an
     ambiguous project ID (APID) to the detection.  The APID simply
     represents the fact that the detection could belong to either
     project P1 or project P2.  APIDs play the role of projectID
     in most cases, but are negative, to distinguish them from
     real project IDs, which are positive.  If two tags from the
     same project are ambiguous, then their ambigProjectID has
     only projectID1 not null.

   - fields in the returned object are arrays:
      - ambigProjectID: integer; (APID) a unique negative projectID
        representing the set {projectID1, ..., projectID6}
      - projectID1: integer; first real (positive) project ID in the set (not null)
      - projectID2: integer; second real project ID in the ambiguity set
      - projectID3: integer; third real project ID in the ambiguity
      - projectID4: integer; fourth real project ID in the ambiguity
      - projectID5: integer; fifth real project ID in the ambiguity
      - projectID6: integer; sixth real project ID in the ambiguity

   - in each record, any non-NULL `projectID...` fields are in
        increasing order (i.e. projectID1 < projectID2 < ...), and
        non-NULL values precede NULL values (i.e. if projectID3 is
        null, then so are projectID4... projectID6).  Moreover, at least
        projectID1 is not null (it is possible to have a record
        with a single non-null projectID; this represents detections which
        are ambiguous among tags within the *same* project)

### pulse counts for receiver ###

   pulse_counts_for_receiver (batchID, ant, hourBin, authToken)

       - batchID: integer; batchID
       - ant: integer; antenna number
       - hourBin: double; the hourBin is defined as floor(timestamp / 3600), where timestamp is the usual
         "seconds since 1 Jan 1970 GMT" unix timestamp.
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"batchID":111,"ant": 0,"hourBin":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/pulse_counts_for_receiver

   - return hourly pulse records from batch `batchID` which haven't already
     been obtained.  These give, for each antenna, the number of pulses
     detected on that antenna during the time period `[hour * 3600,
     (hour + 1) * 3600)`.  The pair (ant, hourBin) is for the latest
     record already obtained, when sorted by hourBin *within* ant.
     The first call for a given batch should use `hourBin=0`, which
     indicates *no* pulse counts have been obtained for that batch
     yet.  In that case, `ant` is ignored.

   - the returned object has these array fields:
     - batchID: integer; same as passed parameter
     - hourBin: double; floor(timestamp / 3600) for pulses represented by this bin
     - ant: integer; antenna number
     - count: integer; number of pulses on this antenna during this hourBin

Paging for this query is achieved by using the last returned values of
`ant` and `hourBin` as `ant` and `hourBin` on subsequent calls.  When
there are no further pulse counts, the API returns an empty list.

Note that this API returns pulses sorted by hourBin within antenna for each batch.

For regular users, this only returns pulse counts if the user has permission for
the project which owns the receiver deployment covering this batch.

For admin users, *all* pulse counts are returned, regardless of batch ownership
(or lack thereof).
