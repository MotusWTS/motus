This document outlines how to use the
[motus R package](https://github.com/jbrzusto/motus) to obtain and
work with your motus detection data.

## Authentication ##

The first time you call a function in the motus package that needs to
authenticate you at motus.org, you will be asked for a username and
password.  This will only happen once per R session.

## Tag Databases ##

Your copy of a tag database is stored as an [SQLite](http://www.sqlite.org)
file with the extension `.motus`, whose schema is described in another
document.

There are two *flavours* of tag database:

1. **receiver tag database**: all detections of any tags from a single receiver.
A receiver tag database has a name like `SG-1234BBBK5678.motus`; where the name
is the serial number of the receiver.

1. **project tag database**: all detections of *your* tags from across the motus network
A project tag database has a name like `project-123.motus`, where the number
is the motus project ID.

These correspond to the basic model of data sharing:

1. you get all detections of anyone's tags by *your* receivers (so, one receiver tag database
for each receiver you deploy)

1. you get all detections of *your* tags by *anyone's* receivers (so, one project tag database
for each of your motus projects)

Internally, the databases formats are almost identical, but a table called "meta" has fields
that differ between the two.

The sqlite format was chosen because:

1. it is flexible, allowing for many data formats

1. it is accessible from many software platforms (not just R) because SQLite bindings are
available for all major programming languages

1. it is **appendable**: the database can be created and updated on disk without
having to read in and resave the entire contents.

Points 2 and 3 are in contrast to the native R `.rds` format.  `.rds` format has the benefit
of taking up less space on disk, but accessing *any* data from it requires reading *all* of it
into memory.

## R functions to create and update your tag database ##

The motus packages provides one basic function to create and update
tag databases of both kinds.  Here's how it works:

```R
# create and open a local tag database for motus project 14 in the
# current directory

tagme(proj=14, new=TRUE)

# update and open the local tag database for motus project 14;
# it must already exist and be in the current directory

tagme(proj=14, update=TRUE)

# update and open the local tag database for a receiver;
# it must already exist and be in the current directory

tagme(recv="SG-1234BBBK4567", update=TRUE)

# open the local tag database for a receiver, without
# updating it

tagme(recv="SG-1234BBBK4567")

```
Each of these functions returns a `dplyr::src_sqlite` that refers to the
database file on disk.  So you can use all the dplyr functions to
filter and summarize your data.  The format of tables in these databases
is described elsewhere.  Most users will find the table called `alltags`
has everything they need.

For example, to find the first hourly detection of each tag in each hour
by receiver and antenna, you could do this:

```R
library(motus)
db = tagme(proj=14)
hourly = db %>% distinct (recv, ant, tagID, floor(ts / 3600))
```

By default, tag databases are stored in the current directory (`getwd()` in R).
You can change this by adding the `dir=` parameter to function calls; e.g.:

```R
db = tagme(proj=14, dir="c:/Users/emily/telemetry/HEGU")
```

To prevent downloading the same data many times, the `tagme()` function requires
that the database already exist, unless you use the `new=TRUE` parameter.
If you use `new=TRUE`, a new database is created, but you will be prompted
to make sure you really want to download all the data.  If you want to
avoid being prompted, e.g. if running from a script, you can add the `force=TRUE`
parameter; e.g.:

```R
## download and open a new copy of the full tag database for motus project 14,
## without prompting the user for confirmation

db = tagme(proj=14, new=TRUE, force=TRUE, dir="/home/john/Desktop")
```

Sometimes, you might want to know approximately how much new data is available
for your project without actually downloading it.  You can do this:

```R
### ask how much new data motus.org has for your project

tellme(proj=14)
```
This returns a named list with these items:

 - **numBatches**: number of batches of new data
 - **numRuns**: number of runs of new tag detections
 - **numHits**: number of new tag detections
 - **size**: approximate size of data transfer required, in megabytes

Of course, *new* means data you do not already have, so the `tellme` function
needs to know where your existing tag database files are.  If they are not in the
current directory, then you can use the `dir` parameter to say where they are; e.g.:

```R
tellme(proj=14, dir="c:/Users/emily/telemetry/HEGU")
```

If you want to know how much data is available for a project but you *do not* already
have a database for it, use the `new` parameter:

```R
tellme(proj=14, new=TRUE)
```
Otherwise, `tellme` will return an error saying it doesn't know where your existing
database is.
