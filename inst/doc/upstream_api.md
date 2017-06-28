# The motus R package upstream API #

The motus R package maintains your copy of a tag detection database.
The database is built from data provided by a server, typically at
motus.org This document describes the API calls required by the motus
package; i.e. what requests must a server respond to if it is to work
with this package.


## API calls ##

## authenticate user ##

   authenticate_user (user, password)

      - user: username
      - password: password (in cleartext)

   - returns a list with these items:
      - token: character string; 264 random bits, base64-encoded
      - expiry: numeric timestamp of expiry for token
      - userID: integer motus ID for user
      - projects: integer vector of project #s user is allowed to request tag detections for
      - receivers: character vector of serial #s of receivers user is allowed to request tag detections for

   or

   - a list with this item:
      - error: "authentication failed"

### Notes ###

1. The token returned by this API must be included in all other API
calls as the parameter called `authToken`.

2. Authorization is by project: if a user has permission for a
project, then that user can see:

   - all batches, runs, and hits for receiver deployments by that project

   - all runs and hits for tag deployments by that project

Calls where no authorized data are available return an appropriate
data.frame with zero rows.

"Ownership" of detections follows these assumptions:

- tag runs nest within tag deployments:  either all or none of the detections of a tag
run belong to a given tag deployment; i.e. we assume the tag is deactivated
for at least ~ 20 minutes between deployments under **different** projects.

- batches nest within receiver deployments:  either all or none of the detections in a
batch belong to a given receiver deployment; i.e. we assume the receiver is
rebooted at least once between deployments under **different** projects.

These assumptions allow for simpler, more efficient database queries.

### batches_for_tag_project (projectID, batchID, authToken) ###

       - projectID: integer project ID
       - batchID: integer largest batchID we already have for this project
       - authToken: authorization token returned by authenticate_user

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

### batches_for_receiver_project (projectID, batchID, authToken) ###

       - projectID: integer project ID
       - batchID: integer largest batchID we already have for this project
       - authToken: authorization token returned by authenticate_user

   - return a list of all batches from receivers in project projectID,
     where the batchID is > `batchID`

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

### runs_for_receiver_project (projectID, batchID, runID, authToken) ###

       - projectID: integer project ID; project receiver belongs to
       - batchID: integer batch ID
       - runID: integer largest runID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

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

### hits_for_receiver_project (projectID, batchID, hitID, authToken) ###

       - projectID; integer project ID of receiver deployment
       - batchID: integer batchID
       - hitID: integer largest hitID we *already* have from this batch
       - authToken: authorization token returned by authenticate_user

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

### gps_for_receiver_project (projectID, batchID, ts, authToken) ###

    - projectID; integer project ID of receiver deployment
    - batchID: integer batchID
    - ts: largest gps timestamp we *already* have for this batch
    - authToken: authorization token returned by authenticate_user

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

### gps_for_tag_project (projectID, batchID, ts, authToken) ###

    - projectID; integer project ID of tags
    - batchID: integer batchID where tags from projectID were detected
    - ts: largest gps timestamp we *already* have for this batch
    - authToken: authorization token returned by authenticate_user

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

### metadata for tags (motusTagIDs, authToken) ###

    - motusTagIDs: integer vector of motus tag IDs; tag metadata will
      only be returned for tag deployments whose project has indicated
      their metadata are public, or tags deployments by one of the
      projects the user has permissions to.
    - authToken: authorization token returned by authenticate_user

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

);

### metadata for receivers (deviceIDs, authToken) ###

    - deviceID; integer device ID; receiver metadata will only be
      returned for receivers whose project has indicated their
      metadata are public, or receivers in one of the projects the
      user has permissions to.
    - authToken: authorization token returned by authenticate_user

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

### tags for ambiguities (ambigIDs, authToken) ###

    - ambigIDs; integer tag ambiguity IDs; this a vector of negative
      integers, each representing 2 to 6 tags for which detections are
      indistinguishable over some period of time; i.e. a detection of
      the given ambigID could represent any of the motus tagIDs.  (6 is
      an implementation limit, not a conceptual one.)
    - authToken: authorization token returned by authenticate_user

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


### size_of_update_for_tag_project (projectID, batchID) ###

    - projectID: integer project ID
    - batchID: integer ID of largest batch client already has

   - return a list with these scalar items:
      - numBatches
      - numRuns
      - numHits
      - numGPS
      - numBytes: estimated uncompressed size of data transfer

### size_of_update_for_receiver_project (projectID, batchID) ###

    - projectID: integer project ID
    - batchID: integer ID of largest batch client already has

   - return a list with these scalar items:
      - numBatches
      - numRuns
      - numHits
      - numGPS
      - numBytes: estimated uncompressed size of data transfer
