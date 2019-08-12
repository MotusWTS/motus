### How the motus data server handles ambiguous tag detections ###

#### How ambiguous detections arise ####

A run of detections is **ambiguous** if there is more than one
deployed tag which could be its source.  The conceptual cause is that
there are two or more tags with the same Lotek ID code, burst
interval, and nominal transmit frequency (i.e. two
**indistinguishable** tags) deployed with overlapping lifetimes.  The
lifetimes are modelled and so not exact, and have a 50% (as of 2017
Oct. 5) margin of safety added, which might be too generous, but we
wanted to err on the side of having ambiguous detections rather than
on the side of missing detections entirely.

#### How the tag finder records an ambiguous detection ####

When the tag finder notices that two (or more, up to 6) deployments of
identical tags overlap, any run of detections of the tag during the
overlap are **ambiguous** and instead of arbitrarily choosing one tag
or the other as the *detected* tag, it preserves the uncertainty by
assigning a unique **ambiguous tag ID**, that represents *either tag A
or tag B*.  For convenience, these ambiguous IDs are chosen to be
negative; that makes them easily distinguishable from IDs of real
tags.  So a negative `motusTagID` represents a unique set of from 2 to
6 real (positive) motus tag IDs.  The real tag IDs represented by an
ambiguous tag ID can be found using the API call
[tags_for_ambiguities](https://github.com/jbrzusto/motusClient/blob/master/inst/doc/upstream_api.md#tags-for-ambiguities-ambigids-authtoken)

#### Why ambiguous detections were missing from tag project databases ####

The reason ambiguous detections failed to show up in the tag project
databases built using the `*_for_tag_project` entries in the data API
is that I hadn't figured out how to decide which projects should
receive which ambiguous runs (or just forgot, more likely).  A user is
not supposed to receive detections of other people's tags except when
detected by the user's own receivers (and ambiguous detections *were*
showing up in databases built with the `*_for_recv` API entries).

#### A lightweight solution ####

One approach is to generate "ambiguous" project IDs, and assign
ambiguous runs to those.  So for example, if a tag 123 with BI 4.3
at 166.38 MHz (`123:4.1@166.38`) seconds was deployed by projects 5
(as motus tag ID 5000) and 10 (as motus tag ID 6000) with overlapping
lifespans, then runs of tag `123:4.3@166.38` in the overlap would be
assigned a unique negative "ambiguous" tag ID (e.g. -50), representing
"motus tag ID 5000 or 6000".  And the run of detections is assigned to
a unique "ambiguous" project ID (e.g. -7) representing "motus project
5 or 10" (using negative ID numbers again, for convenience).

So far, that does nothing.  What makes it useful is these changes:

#### Changes to the API ####

 - project P can request a list of all ambiguous projects that it belongs to.
   That's the horribly-named API entry
   [project_ambiguities_for_tag_project](https://github.com/jbrzusto/motusClient/blob/master/inst/doc/upstream_api.md#project_ambiguities_for_tag_project-projectid)

 - project P is granted access to all runs of detections assigned to
   any ambiguous project that P belongs to.  In the example above,
   that means project 5 would get access to all runs of detections
   from projects 5 and -7.  And project 10 would get access to all
   runs of detections from projects 10 and -7.  This is a conceptual
   change.

#### Changes to the [motusClient](https://github.com/jbrzusto/motusClient) package ####

 - calling `tagme(P)` now requests the list of ambiguous project IDs
   that project P has access to (P is a postive motus project ID)

 - after fetching new detections for the main project, tagme() also
   fetches new detections for its related ambiguous projects.  In the
   example, tagme(5, update=TRUE) would first fetch new detections in
   project 5, and then new detections in project -10 (and in any other
   ambiguous projects on the list).  All of these fetches are
   incremental, and nothing has changed from the users's point of
   view, except that many new detections are fetched (more on that
   in another document) and stored in the *same* database, (e.g. `project-5.motus`)

 - the `tagAmbig` table gains a new field `ambigProjectID` that indicates which
   ambiguous project ID these detections belong to.  For concretness, here are the
   first 5 (out of 339) lines of the augmented `tagAmbig` table:

```sql
sqlite> select * from tagAmbig limit 5;
ambigID     masterAmbigID  motusTagID1  motusTagID2  motusTagID3  motusTagID4  motusTagID5  motusTagID6  ambigProjectID
----------  -------------  -----------  -----------  -----------  -----------  -----------  -----------  --------------
-331         (column       19583        23094                                                            -36
-330          obsolete)    19584        23095                                                            -36
-329                       19595        23107                                                            -36
-312                       15875        22607                                                            -44
-309                       18284        20128                                                            -43
```

#### Changes to the [motusServer](https://github.com/jbrzusto/motusServer) package ####

 - the [dataServer()](https://github.com/jbrzusto/motusServer/blob/new_server/R/dataServer.R)
   now supports the `project_ambiguities_for_tag_project` API entry,
   by maintaining a new `projAmbig` table. For concreteness, here are
   5 rows of that table (from a total of 56):

```sql
MariaDB [motus]> select * from projAmbig where ambigProjectID in (-36, -43, -44, -50, -55);
+----------------+------------+------------+------------+------------+------------+------------+---------+
| ambigProjectID | projectID1 | projectID2 | projectID3 | projectID4 | projectID5 | projectID6 | tsMotus |
+----------------+------------+------------+------------+------------+------------+------------+---------+
|            -55 |         92 |        103 |       NULL |       NULL |       NULL |       NULL |      -1 |
|            -50 |         74 |       NULL |       NULL |       NULL |       NULL |       NULL |      -1 |
|            -44 |         57 |       NULL |       NULL |       NULL |       NULL |       NULL |      -1 |
|            -43 |         57 |         92 |       NULL |       NULL |       NULL |       NULL |      -1 |
|            -36 |         47 |         57 |       NULL |       NULL |       NULL |       NULL |      -1 |
+----------------+------------+------------+------------+------------+------------+------------+---------+
```

   So combining information from the above two tables, the pair of
   ambiguous tags 19583 and 23094 must belong to the projects 47 and
   57 because the ambiguous tag -331 is in ambiguous project -36.
   (The 6 component ID fields in each row in these two tables are in
   sorted order, so by themselves don't indicate whether tag 19583 is
   in project 57 or is in project 47.  The sorted order is easier to
   work with when building and searching these tables.)

   Note that some ambiguous projectIDs have only one non-null
   projectID; this represents an overlap between two or more identical
   tags in *the same* project.  For such tags, ownership of detections
   is obvious, but the same mechanism still serves to fetch ambiguous
   detections and let the user handle them appropriately.

 - the dataServer calculates which `ambigProjectID`s a given real project P
   has access to (answer: any row in which P appears in one of the `projectID*`
   fields.

 - when the [tag finder](https://github.com/jbrzusto/find_tags) runs
   and new ambiguous detections are merged into the master database,
   it checks whether the ambiguous tag ID is new, and if so, ensures
   that an appropriate entry is created in the `projAmbig` table

#### Summary ####

 - ambiguous project IDs are managed in analogy to ambiguous tag IDs

 - a run of detections that could be either tag T1 from project P1 or tag T2 from
   project P2 generates:
      - an ambiguous tagID that represents "T1 or T2"
      - an ambiguous projectID that represents "P1 or P2"
      - the run is of tag "T1 or T2" and is owned by "P1 or P2"

 - when project P1 asks for its tags using `tagme()`, it will also receive tags belonging
   to project "P1 or P2"

 - this approach does not duplicate batch, run, or hit records in the master database,
   but adds `ambigProj`, a small table

 - the server code and API require no changes for fetching ambiguous runs (and batches, hits) that *could*
   belong to project P1.

 - a separate document will describe how users can work with ambiguous detections.
