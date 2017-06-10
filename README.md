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


## What's working so far:

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
