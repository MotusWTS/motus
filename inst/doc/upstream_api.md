# The motus R package upstream API #

The motus R package maintains your copy of a tag detection database.
The database is built from data provided by a server, typically at
motus.org This document describes the API calls required by the motus
package; i.e. what requests must a server respond to if it is to work
with this package.

## API summary ##

### Request ###
 - requests are sent by the HTTP POST method
 - the request has header `Content-Type: application/x-www-form-urlencoded`
 - the POST data has a single item called `json`
 - the fields of `json` are the parameters listed for each API entrypoint below.
 - most requests require an `authToken` value, which can be obtained by a call
   to `authenticate_user`

### Reply ###
 - is a json object: header `Content-Type = application/json`
 - is bzip2-compressed: header `Content-Encoding = bzip2`
 - most return values are lists of vectors of
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

### api_info (authToken) ###

   - return a list with these items:

      - maxRows: integer, maximum number of rows returned by a query

      e.g.
      curl https://sgdata.motus.org/data/custom/api_info


## authenticate user ##

   authenticate_user (user, password)

      - user: username
      - password: password (in cleartext)

      e.g.
      curl --data-urlencode json='{"user":"someone","password":"bigsecret"}' https://sgdata.motus.org/data/custom/authenticate_user

   - returns a list with these items:
      - authToken: character string; 264 random bits, base64-encoded
      - expiry: numeric timestamp of expiry for token
      - userID: integer motus ID for user
      - projects: integer vector of project #s user is allowed to request tag detections for
      - receivers: character vector of serial #s of receivers user is allowed to request tag detections for

   or

   - a list with this item:
      - error: "authentication with motus failed"

### Notes ###

1. The `authToken` returned by this API must be included in most other API calls.

2. Authorization is by project: if a user has permission for a
project, then that user can see:

   - all batches, runs, and hits for receiver deployments by that project

   - all runs and hits for tag deployments by that project

If an API call does not find any data for which the user is
authorized, it will return a json object of the usual structure,
except that column arrays will have length zero.  This represents an R
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

### deviceID_for_receiver (serno, authToken) ###

       - serno: character vector of receiver serial number(s)

      e.g.
      curl --data-urlencode json='{"serno":"SG-1234BBBK5678","authToken":"XXX"}' https://sgdata.motus.org/data/custom/deviceID_for_receiver

   - return a list of receiver device IDs for the given serial numbers

   - items in the return value are vectors:
      - serno character serial number, as specified
      - deviceID integer motus device ID, or NA where the serial number was not found

### receivers_for_project (projectID, authToken) ###

       - projectID: integer project ID

      e.g.
      curl --data-urlencode json='{"projectID":123,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/receivers_for_project

   - return a list of receiver deployments belonging to project `projectID`

   - items in the return value are vectors:
      - serno character serial number; e.g. SG-1234BBBK9876, Lotek-149
      - receiverType character; "LOTEK" or "SENSORGNOME"
      - deviceID integer motus device ID
      - status character,
      - deployID integer; motus device deployment ID
      - name character; short name for this deployment; typically a site name
      - fixtureType character; e.g. "PopTower"
      - latitude numeric; decimal degrees North (at start of deployment if mobile)
      - longitude numeric; decimal degrees East (at start of deployment if mobile)
      - isMobile logical; is this a mobile deployment
      - tsStart numeric; unix timestamp of start of deployment
      - tsEnd numeric; unix timestamp of end of deployment, or null if still deployed
      - projectID integer; motus project ID owning deployment
      - elevation numeric; metres above sea level

### batches_for_tag_project (projectID, batchID, authToken) ###

       - projectID: integer project ID
       - batchID: integer largest batchID we already have for this project
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":0, "authToken":"XXX"}' https://sgdata.motus.org/data/custom/batches_for_tag_project

   - return a list of all batches with detections of tags in project `projectID`,
     where the batchID is > `batchID`

   - items in the return value are vectors (as they exist in the transfer
     tables):
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

### batches_for_receiver (deviceID, batchID, authToken) ###

       - deviceID: integer motus device ID, e.g. as returned by receivers_for_project
       - batchID: integer largest batchID we already have for this project
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":0, "authToken":"XXX"}' https://sgdata.motus.org/data/custom/batches_for_receiver

   - return a list of all batches from deployments of the device by
     project projectID, where the batchID is > `batchID`

   - columns should include these fields (as they exist in the transfer
     tables):
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

### runs_for_tag_project (projectID, batchID, runID, authToken) ###

       - projectID: integer project ID
       - batchID: integer batch ID
       - runID: integer largest run ID we *already* have from this batch and tag project
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":111,"runID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/runs_for_tag_project

   - return a list of all runs of a tag in project `projectID`, from batch
     `batchID` and with run ID > `runID`

   - columns should include these fields (as they exist in the transfer
     tables):
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

### runs_for_receiver (batchID, runID, authToken) ###

       - batchID: integer batch ID
       - runID: integer largest runID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":111,"runID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/runs_for_receiver

   - return a list of all runs from batch `batchID` with run ID > `runID`

   - columns should include these fields (as they exist in the transfer
     tables):
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

### hits_for_tag_project (projectID, batchID, hitID, authToken) ###

       - projectID: integer project ID
       - batchID: integer batchID
       - hitID: integer largest hitID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":111,"hitID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/hits_for_tag_project

   - return a list of all hits on tags in project `projectID` which are in batch `batchID`,
     and whose hit ID is > `hitID`

   - columns should include these fields (as they exist in the transfer
     tables):
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

### hits_for_receiver (batchID, hitID, authToken) ###

       - batchID: integer batchID
       - hitID: integer largest hitID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"batchID":111,"hitID":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/hits_for_receiver

   - return a list of all hits in batch `batchID` whose hit ID is > `hitID`

   - columns should include these fields (as they exist in the transfer
     tables):
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

### gps_for_tag_project (projectID, batchID, ts, authToken) ###

       - projectID; integer project ID of tags
       - batchID: integer batchID where tags from projectID were detected
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

   - columns should include these fields (as they exist in the transfer
     tables):
     - ts
     - batchID (optional; this is just batchID)
     - lat
     - lon
     - alt

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further GPS fixes, the API
returns an empty list.

### gps_for_receiver (batchID, ts, authToken) ###

       - batchID: integer batchID
       - ts: largest gps timestamp we *already* have for this batch
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"batchID":111,"ts":0,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/gps_for_receiver

   - return all GPS fixes from batch batchID which are later than timestamp ts

   - columns should include these fields (as they exist in the transfer
     tables):
     - ts
     - batchID (optional; this is just batchID)
     - lat
     - lon
     - alt

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further GPS fixes, the API
returns an empty list.

### metadata for tags (motusTagIDs, authToken) ###

       - motusTagIDs: integer vector of motus tag IDs; tag metadata will
         only be returned for tag deployments whose project has indicated
         their metadata are public, or tags deployments by one of the
         projects the user has permissions to.
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"motusTagIDs":[12345,12346,12347],"authToken":"XXX"}' https://sgdata.motus.org/data/custom/metadata_for_tags

   - return a list with these items:

      - tags; a list with these columns:
         - tagID; integer tag ID
         - projectID; integer motus ID of project which *registered* tag
         - mfgID; character manufacturer tag ID
         - type; character  "ID" or "BEEPER"
         - codeSet; character e.g. "Lotek3", "Lotek4"
         - manufacturer; character e.g. "Lotek"
         - model; character e.g. "NTQB-3-1"
         - lifeSpan; integer estimated tag lifeSpan, in days
         - nomFreq; numeric nominal frequency of tag, in MHz
         - offsetFreq; numeric estimated offset frequency of tag, in kHz
         - bi; numeric burst interval or period of tag, in seconds
         - pulseLen; numeric length of tag pulses, in ms (not applicable to all tags)

      - tagDeps; a list with these columns:
         - tagID; integer motus tagID
         - deployID; integer tag deployment ID (internal to motus)
         - projectID; integer motus ID of project which *deployed* tag
         - tsStart; numeric timestamp of start of deployment
         - tsEnd; numeric timestamp of end of deployment
         - deferSec; integer deferred activation period, in seconds (0 for most tags).
         - speciesID; integer motus species ID code
         - markerType; character type of marker on organism; e.g. leg band
         - markerNumber; character details of marker; e.g. leg band code
         - latitude; numeric deployment location, degrees N (negative is S)
         - longitude; numeric deployment location, degrees E (negative is W)
         - elevation; numeric deployment location, metres ASL
         - comments; character possibly JSON-formatted list of additional metadata

      - species; a list with these columns:
         - id; integer species ID,
         - english; character; English species name
         - french; character; French species name
         - scientific; character; scientific species name
         - group; character; higher-level taxon

      - projs; a list with these columns:
         - id; integer motus project id
         - name; character full name of motus project
         - label; character short label for motus project; e.g. for use in plots
);

### metadata for receivers (deviceIDs, authToken) ###

       - deviceID; integer device ID; receiver metadata will only be
         returned for receivers whose project has indicated their
         metadata are public, or receivers in one of the projects the
         user has permissions to.
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"deviceIDs":[123,124,125],"authToken":"XXX"}' https://sgdata.motus.org/data/custom/metadata_for_receivers

   - return a list with these items:

      - recvDeps; a list with these columns:
         - deployID; integer deployment ID (internal to motus, but links to antDeps)
         - projectID; integer ID of project that deployed the receiver
         - serno; character serial number, e.g. "SG-1214BBBK3999", "Lotek-8681"
         - receiverType; character "SENSORGNOME" or "LOTEK"
         - deviceID; integer device ID (internal to motus)
         - status; character deployment status
         - name; character; typically a site name
         - fixtureType; character; what is the receiver mounted on?
         - latitude; numeric (initial) location, degrees North
         - longitude; numeric (initial) location, degrees East
         - elevation; numeric (initial) location, metres ASL
         - isMobile; integer non-zero means a mobile deployment
         - tsStart; numeric; timestamp of deployment start
         - tsEnd; numeric; timestamp of deployment end, or NA if ongoing

      - antDeps; a list with these columns:
         - deployID; integer, links to deployID in recvDeps table
         - port; integer, which receiver port (USB for SGs, BNC for
           Lotek) the antenna is connected to
         - antennaType; character; e.g. "Yagi-5", "omni"
         - bearing; numeric compass angle at which antenna is pointing; degrees clockwise from
           magnetic north
         - heightMeters; numeric height of main antenna element above ground
         - cableLengthMeters; numeric length of coaxial cable from antenna to receiver, in metres
         - cableType: character; type of cable; e.g. "RG-58"
         - mountDistanceMeters; numeric distance of mounting point from receiver, in metres
         - mountBearing; numeric compass angle from receiver to antenna mount; degrees clockwise from
           magnetic north
         - polarization2; numeric angle giving tilt from "normal" position, in degrees
         - polarization1; numeric angle giving rotation of antenna about own axis, in degrees.

      - projs; a list with these columns:
         - id; integer motus project id
         - name; character full name of motus project
         - label; character short label for motus project; e.g. for use in plots

### tags for ambiguities (ambigIDs, authToken) ###

       - ambigIDs; integer tag ambiguity IDs; this a vector of negative
         integers, each representing 2 to 6 tags for which detections are
         indistinguishable over some period of time; i.e. a detection of
         the given ambigID could represent any of the motus tagIDs.  (6 is
         an implementation limit, not a conceptual one.)
       - authToken: authorization token returned by authenticate_user

      e.g.
      curl --data-urlencode json='{"ambigIDs":[-3,-4,-5],"authToken":"XXX"}' https://sgdata.motus.org/data/custom/tags_for_ambiguities

   - return a list with these vector items:
      - ambigID; negative integer tag ambiguity ID
      - motusTagID1; positive integer motus tag ID
      - motusTagID2; positive integer motus tag ID
      - motusTagID3; positive integer motus tag ID or null
      - motusTagID4; positive integer motus tag ID or null
      - motusTagID5; positive integer motus tag ID or null
      - motusTagID6; positive integer motus tag ID or null

      i.e. return what real tags each ambiguityID represents.
      If `motusTagIDM[i]` is null, then `motusTagIDN[i]` is also null for
      `M < N <= 6`; i.e. non-null values precede null values
      for each ambiguity.


### size_of_update_for_tag_project (projectID, batchID, authToken) ###

       - projectID: integer project ID
       - batchID: integer ID of largest batch client already has

      e.g.
      curl --data-urlencode json='{"projectID":123,"batchID":15538,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/size_of_update_for_tag_project

   - return a list with these scalar items:
      - numBatches
      - numRuns
      - numHits
      - numGPS
      - numBytes: estimated uncompressed size of data transfer

### size_of_update_for_receiver (deviceID, batchID, authToken) ###

       - deviceID: integer motus device ID
       - batchID: integer ID of largest batch client already has

      e.g.
      curl --data-urlencode json='{"deviceID":221,"batchID":15538,"authToken":"XXX"}' https://sgdata.motus.org/data/custom/size_of_update_for_receiver

   - return a list with these scalar items:
      - numBatches
      - numRuns
      - numHits
      - numGPS
      - numBytes: estimated uncompressed size of data transfer
