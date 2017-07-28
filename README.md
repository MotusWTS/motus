# motus
R package for users of data from http://motus.org

**Users**: the 'master' branch is what you want.  You can install it
from R by doing:
```R
    install.packages("devtools")              ## if you haven't already done this

    install_github("jbrzusto/motus@master")   ## the lastest stable version
```

**Developers**: the 'staging' branch is for work-in-progress.  Install it with
```R
    install.packages("devtools")               ## if you haven't already done this

    install_github("jbrzusto/motus@staging")   ## the development version
```

## Usage vignette

A brief sketch is [here](https://github.com/jbrzusto/motus/blob/staging/inst/doc/motus_R_package_usage.md)

## What's working so far:

### 2017 Jul 28

- tagme() - for updating local copies of receiver or tag project detection databases
- tellme() - for asking how much data will need to be transferred by the corresponding tagme() call

The latest version of the data server that works with this package is
now running on a new box, but its database is only populated with data
from 4 (!) receivers.  Raw files from other receivers will be re-run with
the latest version of the tag finder and added to this database.  Only
those users willing to wrestle with alpha code and not actually interested
in getting their data should be using this package for now.

### 2017 Jun 10

- srvTagsForAmbiguities()
- srvMetadataForReceivers()

### 2017 Jun 8

- srvGPSforTagProject()
- srvMetadataForTags()

### 2017 Jun 6

- srvRunsForReceiverProject()
- srvHitsForTagProject()
- srvHitsForReceiverProject()
- srvGPSforReceiverProject()

### 2017 May 31

- srvRunsForTagProject()
- srvBatchesForTagProject()
- srvBatchesForReceiverProject()

### 2017 May 19

- authentication against local data server

### 2017 Feb 7

- some R functions for post-processing

### 2016 Dec 1
- nothing (yes, nothing is working; in fact, nothing is working beautifully)
