# motus 1.5.0 (2019-03-28)

### Big Changes
* Combined `motus` and `motusClient` packages
* New function `activity()` adds hit activity for batches to a new `activity` table in the SQLite database. This is useful for detecting 'noisy' periods where hits may be unreliable.

### New Features
* Added a `NEWS.md` file to track changes to the package
* Added support for `httr` for server queries
* Added `?motus` package documentation
* Added unit testing 

### Bug Fixes
* Fix references to `ggmap` to avoid having to get Google API keys


# motus 1.0.0

### 2017 Sep 25

- tagme() / tellme() and supporting functions are now in the [motusClient](https://github.com/motusWTS/motusClient)
package, which is automatically installed from github the first time you do `library(motus)` after installing
the `motus` package.  If automatic installation of `motusClient` fails, you can install it directly like so:
```R
install_github("motusWTS/motusClient")
```

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