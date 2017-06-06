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
calls as a parameter called `authToken`.  This is not shown in the
prototypes below.

2. Authorization is by project: if a user has permission for a
project, then that user can see:

   - all batches, runs, and hits for receiver deployments by that project

   - all runs and hits for tag deployments by that project

Calls where no authorized data are available return an appropriate
data.frame with zero rows.

### batches_for_tag_project (projectID, ts) ###

       - projectID: integer project ID
       - ts: numeric timestamp

   - return a list of all batches with detections of tags in project `projectID`,
     where the processing timestamp of the batch is > `ts`

   - items in the return value are vectors (as they exist in the transfer
     tables):
      - batchID
      - motusDeviceID
      - monoBN
      - tsBegin
      - tsEnd
      - numHits
      - ts

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further batches, the API
returns an empty list.

### batches_for_receiver_project (projectID, ts) ###

       - projectID: integer project ID
       - ts: numeric timestamp

   - return a list of all batches from receivers in project projectID,
     where the processing timestamp of the batch is > `ts`

   - columns should include these fields (as they exist in the transfer
     tables):
      - batchID
      - motusDeviceID
      - monoBN
      - tsBegin
      - tsEnd
      - numHits
      - ts

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further batches, the API
returns an empty list.

### runs_for_tag_project (projectID, batchID, runID) ###

       - projectID: integer project ID
       - batchID: integer batch ID
       - runID: integer largest run ID we *already* have from this batch and tag project

   - return a list of all runs of a tag in project `projectID`, from batch
     `batchID` and with run ID > `runID`

   - columns should include these fields (as they exist in the transfer
     tables):
      - runID
      - batchIDbegin
      - batchIDend
      - motusTagID
      - ant
      - len

Paging for this query is achieved by using the last returned value of `runID`
as `runID` on subsequent calls.  When there are no further runs, the API
returns an empty list.

### runs_for_receiver_project (projectID, batchID, runID) ###

       - projectID: integer project ID; project receiver belongs to
       - batchID: integer batch ID
       - runID: integer largest runID we *already* have from this batch

   - return a list of all runs from batch `batchID` with run ID > `runID`

   - columns should include these fields (as they exist in the transfer
     tables):
      - runID
      - batchIDbegin
      - batchIDend
      - motusTagID
      - ant
      - len

Paging for this query is achieved by using the last returned value of `runID`
as `runID` on subsequent calls.  When there are no further runs, the API
returns an empty list.

### hits_for_tag_project (projectID, batchID, hitID) ###

       - projectID: integer project ID
       - batchID: integer batchID
       - hitID: integer largest hitID we *already* have from this batch

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

### hits_for_receiver_project (projectID, batchID, hitID) ###

        - projectID; integer project ID of receiver deployment
        - batchID: integer batchID
        - hitID: integer largest hitID we *already* have from this batch

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

### gps_for_receiver_project (projectID, batchID, ts) ###

  Used when a receiver deployment is marked as 'mobile'.

    - projectID; integer project ID of receiver deployment
    - batchID: integer batchID
    - ts: largest gps timestamp we *already* have for this batch

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
