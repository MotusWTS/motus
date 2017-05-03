# The motus R package upstream API #

The motus R package maintains your copy of a tag detection database.
The database is built from data provided by a server, typically at
motus.org This document describes the API calls required by the motus
package; i.e. what requests must a server respond to if it is to work
with this package.


## API calls ##

### get batches by tag project ###

   batches_for_tag_project (P, TS)

       - P: integer project ID
       - TS: numeric timestamp

   - return a list of all batches with detections of tags in project P,
     where the tsSG of the batch is >= TS

   - columns in the return value should include these fields (as they exist in the transfer
     tables):
      - batchID
      - motusDeviceID
      - monoBN
      - tsBegin
      - tsEnd
      - numHits

### get batches by receiver project ###

   batches_for_receiver_project (P, TS)

       - P: integer project ID
       - TS: numeric timestamp

   - return a list of all batches from receivers in project P,
     where the tsSG of the batch is >= TS

   - columns should include these fields (as they exist in the transfer
     tables):
      - batchID
      - motusDeviceID
      - monoBN
      - tsBegin
      - tsEnd
      - numHits

### get runs by tag project from given batch ###

   runs_for_tag_project (P, B)

       - P: integer project ID
       - B: integer batch ID

   - return a list of all runs of a tag in project P, from the batch
   with ID = B

   - columns should include these fields (as they exist in the transfer
     tables):
      - runID
      - batchIDbegin
      - batchIDend
      - motusTagID
      - ant
      - len

### get all runs from given batch ###

This would be called when building a copy of the receiver database; in
that case, all runs, regardless of tag project, would be provided.

   runs_for_batch (B)

       - B: integer batch ID

   - return a list of all runs from the batch with ID = B

   - columns should include these fields (as they exist in the transfer
     tables):
      - runID
      - batchIDbegin
      - batchIDend
      - motusTagID
      - ant
      - len

Paging for this query is achieved by using the last returned value of `hitID`
as `H` on subsequent calls.

### get all hits by tag project from given batch ###

   hits_for_tag_project_in_batch (P, B, H)

       - P: integer project ID
       - B: integer batchID
       - H: integer largest hitID we *already* have

   - return a list of all hits on tags in project P which are in batch B,
     and whose hit ID is > H

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
as `H` on subsequent calls.

### get all hits from given batch ###

   hits_in_batch (B, H)

        - B: integer batchID
        - H: integer largest hitID we *already* have

   - return a list of all hits in batch B whose hit ID is > H

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

### get all GPS fixes from a given batch ###
  Used when a receiver deployment is marked as 'mobile'.

     gps_in_batch (B, TS)

        - B: integer batchID
        - TS: largest gps timestamp we *already* have

     - return all GPS fixes from batch B which are later than timestamp TS

     - columns should include these fields (as they exist in the transfer
       tables):
        - ts
        - batchID (optional; this is just B)
        - lat
        - lon
        - alt

Paging for this query is achieved by using the last returned value of `ts`
as `TS` on subsequent calls.
