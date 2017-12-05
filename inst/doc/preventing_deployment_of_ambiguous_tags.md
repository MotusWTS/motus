### Preventing Deployment of Ambiguous Tags ###

The problem:

   Given the set of registered tags and their active deployed lifetimes, find any
   ambiguities between them and a set of proposed new tags and deployment dates.

One partial solution already exists: the tag finder builds a tree that
includes nodes representing groups of tags which cannot be
distinguished according to the tag finder's algorithm and parameter
choices.  We can add a command-line option to the tag finder to simply
run through the tag event table and dump all ambiguous groups as tags are activated
and deactivated, then write an R harness with these semantics:

``` R
   findAmbig = function(actual, proposed) {...}
```

where `actual` is a data.frame with these columns:

 - motusID: integer; motus tag ID
 - id: integer; lotek tag ID; e.g. 123
 - bi: double; burst interval in seconds; e.g. 3.2995
 - tsStart: double; starting deployment timestamp (seconds since 1 Jan 1970, GMT)
 - tsEnd: double; ending deployment timestamp (actual, or calculated based on tag model, bi)

and `proposed` is a data.frame with these columns:

 - id: integer; lotek tag ID; e.g. 123
 - codeSet: character; "Lotek3" or "Lotek4" (or ???)
 - bi: double; burst interval in seconds; e.g. 3.2995
 - tsStart: double; starting deployment timestamp (seconds since 1 Jan 1970, GMT)
 - tsEnd: double; ending deployment timestamp (actual, or calculated based on tag model, bi); can be NA
 - model: character; tag model; e.g. "NTQB-4-2"

The return value would be a data.frame representing groups of ambiguous tags,
with these columns:

 - motusID1: integer; motusID of 1st tag in ambiguity group
 - motusID2: integer; motusID of 2nd tag in ambiguity group
 - motusID3: integer; motusID of 3rd tag in ambiguity group (or NA, if none)
 - motusID4                      ...
 - motusID5                      ...
 - motusID6                      ...
 - tsStart: double; timestamp for start of ambiguous period
 - tsEnd: double; timestamp for end of ambiguous period

where tags in the `proposed` data.frame would be assigned consecutive motusIDs starting at -1 and decreasing,
so that they were easy to recognize.

This code would currently have to run on the sgdata server, because it
uses the tag burst pattern and hence the Lotek codeset DB, but the
filter_tags flavour of the tag finder could instead be augmented to
deal with ambiguities as the normal tag finder does, and this
version could run without knowing anything about codesets.
