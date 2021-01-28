# motus 4.0.4
### Bug fixes
* fixed bug resulting in occasional unending download loop of GPS fixes for receivers

# motus 4.0.3

### Bug fixes
* fixed bug resulting in error "no applicable method for 'db_has_table'..."

# motus 4.0.2

### Bug fixes
* fixed rounding error in `filterByActivity()` resulting in mismatched `hourBins`
* fixed incorrect receiver types and model assignment for CTT receivers

# motus 4.0.1

### Bug fixes
* Corrected the server address

# motus 4.0.0

### Small Changes
* Add `test` to metadata in `tagDeps` table to identify test deployments 
  (`tagDeployTest` in `alltags` and `alltagsGPS` views)
* Add `age` and `sex` to metadata in `tagDeps` table
* For CTT SensorStation V2
    * Add `lat_mean`, `lon_mean`, and `n_fixes` to `gps` table
    * Add `nodets`, `firmware`, `solarVolt`, `solarCurrent`, `solarCurrentCumul`, `lat`, and `lon` to `nodeData` table
    * Add `validated` to `hits` table

### Bug fixes
* Downloading hits no longer fails if extra columns are supplied by the server

### Internal changes
* Internal workings of major `motusUpdateXXX()` functions split into multiple
  smaller functions to make testing more efficient
* Added mockery package for mock testing

# motus 3.0.1

### Small Changes
* Receiver downloads now have similar progress messages to Project downloads
* Move GPS fields from `alltags` to `alltagsGPS`
* New function `getGPS()` adds GPS fields to data
* Remove NOT NULL constraint on `motusTagID`s in ambiguous tag view

### Bug fixes
* Receivers updating to the new version errored on the download start
* Allow renaming (if possible) of large databases on data updates
* Continue checking for activity/nodeData even if first batch returns 0
* `nodeDataId` is corrected to `nodeDataID`
* Warn users with custom views if they need to be removed prior to updating

# motus 3.0.0 (2019-10-16)

### Big Changes
* Switch to data version 2
    * Includes new CTT antennas
    * Includes `nodeData` and `nodeDeps` tables for node related data and metadata.

### Small Changes
* Replace all `cat()` with `message()` (now suppressible)
* Add `recvUtcOffset` and `tsCorrected` to `alltags` view
* Add `gpsID` to `gps` table, `gpsID` is now the primary key and index

### Bug fixes
* Fixed bug where `tagme(..., countOnly = TRUE)` failed

# motus 2.0.0 (2019-08-12)

### Big Changes
* Combined `motus` and `motusClient` packages

### New Features
* New function `activity()` adds hit activity for batches to a new `activity` table in the SQLite database. This is useful for detecting 'noisy' periods where hits may be unreliable.
* New function `filterByActivity()` allows users to create custom filters using data from the `activity` table.
* Added a `NEWS.md` file to track changes to the package
* Added support for `httr` for server queries
* Added `?motus` package documentation
* Added unit testing 

### Bug Fixes
* Fix references to `ggmap` to avoid having to get Google API keys

### Other
* Moved dependencies to import rather than depend, to improve attach times, and reduce conflict with user-attached packages (note that `dplyr` will have to be loaded by users now)
* All examples are tested

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
