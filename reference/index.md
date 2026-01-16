# Package index

## Download data

- [`tagme()`](https://motuswts.github.io/motus/reference/tagme.md) :
  Download motus tag detections to a database
- [`tellme()`](https://motuswts.github.io/motus/reference/tellme.md) :
  Report how much new data motus has for a tag detection database
- [`activity()`](https://motuswts.github.io/motus/reference/activity.md)
  : Add/update batch activity
- [`metadata()`](https://motuswts.github.io/motus/reference/metadata.md)
  : Update all metadata
- [`nodeData()`](https://motuswts.github.io/motus/reference/nodeData.md)
  : Add/update nodeData
- [`activityAll()`](https://motuswts.github.io/motus/reference/activityAll.md)
  : Add/update all batch activity
- [`gpsAll()`](https://motuswts.github.io/motus/reference/gpsAll.md) :
  Add/update all GPS points

## Cleaning

Helper functions for cleaning and preparing data

- [`filterByActivity()`](https://motuswts.github.io/motus/reference/filterByActivity.md)
  :

  Filter `alltags` by `activity`

- [`clarify()`](https://motuswts.github.io/motus/reference/clarify.md) :
  Report or claim ambiguous tag detections

- [`deprecateBatches()`](https://motuswts.github.io/motus/reference/deprecateBatches.md)
  : Fetch and remove deprecated batches

## Helper

- [`tagmeSample()`](https://motuswts.github.io/motus/reference/tagmeSample.md)
  : Create an in-memory copy of sample tags data
- [`getGPS()`](https://motuswts.github.io/motus/reference/getGPS.md) :
  Get GPS variables
- [`getRuns()`](https://motuswts.github.io/motus/reference/getRuns.md) :
  Returns a dataframe containing runs
- [`simSiteDet()`](https://motuswts.github.io/motus/reference/simSiteDet.md)
  : Create a dataframe of simultaneous detections at multiple sites
- [`sunRiseSet()`](https://motuswts.github.io/motus/reference/sunRiseSet.md)
  : Obtain sunrise and sunset times
- [`timeToSunriset()`](https://motuswts.github.io/motus/reference/timeToSunriset.md)
  : Obtain time to and from sunrise/sunset
- [`getMotusDBSrc()`](https://motuswts.github.io/motus/reference/getMotusDBSrc.md)
  : Get the src_sqlite for a receiver or tag database
- [`srvTimeout()`](https://motuswts.github.io/motus/reference/srvTimeout.md)
  : Sets global options for timeouts

## Plotting

- [`plotAllTagsCoord()`](https://motuswts.github.io/motus/reference/plotAllTagsCoord.md)
  : Plot all tag detections by latitude or longitude
- [`plotAllTagsSite()`](https://motuswts.github.io/motus/reference/plotAllTagsSite.md)
  : Plot all tag detections by deployment
- [`plotDailySiteSum()`](https://motuswts.github.io/motus/reference/plotDailySiteSum.md)
  : Plots number of detections and tags, daily, for a specified site
- [`plotRouteMap()`](https://motuswts.github.io/motus/reference/plotRouteMap.md)
  : Map of tag routes and sites coloured by id
- [`plotSite()`](https://motuswts.github.io/motus/reference/plotSite.md)
  : Plot all tags by site
- [`plotSiteSig()`](https://motuswts.github.io/motus/reference/plotSiteSig.md)
  : Plot signal strength of all tags by a specified site
- [`plotTagSig()`](https://motuswts.github.io/motus/reference/plotTagSig.md)
  : Plot signal strength of all detections for a specified tag by site
- [`points2Path()`](https://motuswts.github.io/motus/reference/points2Path.md)
  : Convert points to path

## Summarizing

- [`siteSum()`](https://motuswts.github.io/motus/reference/siteSum.md) :
  Summarize and plot detections of all tags by site
- [`siteSumDaily()`](https://motuswts.github.io/motus/reference/siteSumDaily.md)
  : Summarize daily detections of all tags by site
- [`siteTrans()`](https://motuswts.github.io/motus/reference/siteTrans.md)
  : Summarize transitions between sites for each tag
- [`tagSum()`](https://motuswts.github.io/motus/reference/tagSum.md) :
  General summary of detections for each tag
- [`tagSumSite()`](https://motuswts.github.io/motus/reference/tagSumSite.md)
  : Summarize detections of all tags by site

## Filtering

Functions for creating database filters

- [`getRunsFilters()`](https://motuswts.github.io/motus/reference/getRunsFilters.md)
  : Get runsFilters
- [`listRunsFilters()`](https://motuswts.github.io/motus/reference/listRunsFilters.md)
  : Returns a dataframe of the filters stored in the local database.
- [`createRunsFilter()`](https://motuswts.github.io/motus/reference/createRunsFilter.md)
  : Create a new filter records that can be applied to runs
- [`deleteRunsFilter()`](https://motuswts.github.io/motus/reference/deleteRunsFilter.md)
  : Delete a filter
- [`writeRunsFilter()`](https://motuswts.github.io/motus/reference/writeRunsFilter.md)
  : Write to the local database the probabilities associated with runs
  for a filter

## Administration

- [`getAccess()`](https://motuswts.github.io/motus/reference/getAccess.md)
  : Return accessible projects and receivers
- [`motusLogout()`](https://motuswts.github.io/motus/reference/motusLogout.md)
  : Forget login credentials for motus.
- [`checkVersion()`](https://motuswts.github.io/motus/reference/checkVersion.md)
  : Check database version
