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

Note: the token returned by this API must be included in all other API
calls as a parameter called `authToken`.  This is not shown in the prototypes below.

### get batches by tag project ###

   batches_for_tag_project (projectID, ts)

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

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further batches, the API
returns an empty list.

### get batches by receiver project ###

   batches_for_receiver_project (projectID, ts)

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

Paging for this query is achieved by using the last returned value of `ts`
as `ts` on subsequent calls.  When there are no further batches, the API
returns an empty list.

### get runs by tag project from a batch ###

   runs_for_tag_project (projectID, batchID, runID)

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

### get all runs from a batch ###

This would be called when building a copy of the receiver database; in
that case, all runs, regardless of tag project, would be provided.

   runs_for_batch (batchID, runID)

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

### get all hits by tag project from a batch ###

   hits_for_tag_project_in_batch (projectID, batchID, hitID)

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

### get all hits from a batch ###

   hits_in_batch (batchID, hitID)

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

### get all GPS fixes from a batch ###
  Used when a receiver deployment is marked as 'mobile'.

  gps_in_batch (batchID, ts)

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
