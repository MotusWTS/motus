# Removing deprecated batches

``` r
library(motus)
library(tidyverse)

sql_motus <- tagme(176, new = TRUE, dir = "./data/")
```

As work progresses and data are fine-tuned, batches of data may be
re-run on the Motus servers, and as a result, be assigned new batch
numbers (see the section on [Reprocessing
Data](https://motuswts.github.io/motus/articles/motus-data.html#reprocessing-data)
in the [Understanding Motus
Data](https://motuswts.github.io/motus/articles/motus-data.md) article).

This results is a disconnect between the user’s local data and the data
on the server. When the user updates their data, they’ll have the new
batches, but will also have the older, *deprecated* batches.

Users can see which batches have been deprecated in the `deprecated`
table:

``` r
tbl(sql_motus, "deprecated")
```

    ## # Source:   table<`deprecated`> [?? x 3]
    ## # Database: sqlite 3.51.1 [/home/runner/work/motus/motus/vignettes/articles/data/project-176.motus]
    ##   batchID batchFilter removed
    ##     <int>       <int>   <int>
    ## 1    6000           4       0
    ## 2    6001           4       0
    ## 3    6002           4       0
    ## 4    6003           4       0
    ## 5    6004           4       0
    ## 6    6005           4       0

Each `batchID` listed represented a deprecated batch. The column
`removed` indicates whether this batch has been removed from your data
(`1`) or not (`0`).

This table is updated every time you update your data with a call to
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md). If you
want to update it again (without removing anything), you can use

``` r
sql_motus <- deprecateBatches(sql_motus, fetchOnly = TRUE)
## Fetching deprecated batches
## Total deprecated batches: 6
## New deprecated batches: 0
```

To see where these batches are in your data, you can filter for the IDs
in a specific table

``` r
tbl(sql_motus, "alltags") %>%
  filter(batchID %in% c(6000, 6001, 6002))
```

    ## # Source:   SQL [?? x 62]
    ## # Database: sqlite 3.51.1 [/home/runner/work/motus/motus/vignettes/articles/data/project-176.motus]
    ##       hitID   runID batchID          ts tsCorrected   sig sigsd noise  freq freqsd   slop
    ##       <int>   <int>   <int>       <dbl>       <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl>  <dbl>
    ##  1 23271881 1822216    6000 1487894945. 1487894945. -68.2 10.9  -76.3  2.07 0.127  0.0034
    ##  2 23271882 1822216    6000 1487894995. 1487894995. -67.9 18.9  -75.7  1.98 0.185  0.0019
    ##  3 23284651 1828340    6000 1487916706. 1487916706. -68.7 34.9  -76.4  2.00 0.11   0.0045
    ##  4 23284652 1828340    6000 1487916736. 1487916736. -68.9 15.3  -76.7  1.90 0.0315 0.0047
    ##  5 23306136 1838711    6000 1487954561. 1487954561. -68.1  8.84 -76.9  1.92 0.0351 0.0047
    ##  6 23306137 1838711    6000 1487954612. 1487954612. -69.3 14.8  -76.4  1.91 0.0675 0.0013
    ##  7 23306412 1838841    6000 1487954709. 1487954709. -69.7 22.9  -76.8  1.88 0.0356 0.0047
    ##  8 23306413 1838841    6000 1487954759. 1487954759. -69.3 17.8  -76.4  1.88 0.0716 0.0022
    ##  9 23322817 1846692    6000 1488002715. 1488002715. -67.3 15.0  -75.3  1.91 0.116  0.0046
    ## 10 23322818 1846692    6000 1488002746. 1488002746. -67.9 21.5  -76.0  2.00 0.166  0.0048
    ## # ℹ more rows
    ## # ℹ 51 more variables: burstSlop <dbl>, done <int>, motusTagID <int>, ambigID <int>,
    ## #   port <chr>, nodeNum <chr>, runLen <int>, motusFilter <dbl>, bootnum <int>,
    ## #   tagProjID <int>, mfgID <chr>, tagType <chr>, codeSet <chr>, mfg <chr>,
    ## #   tagModel <chr>, tagLifespan <int>, nomFreq <dbl>, tagBI <dbl>, pulseLen <dbl>,
    ## #   tagDeployID <int>, speciesID <int>, markerNumber <chr>, markerType <chr>,
    ## #   tagDeployStart <dbl>, tagDeployEnd <dbl>, tagDepLat <dbl>, tagDepLon <dbl>, …

Deprecated batches can also be removed with the
[`deprecateBatches()`](https://motuswts.github.io/motus/reference/deprecateBatches.md)
function, which, by default, fetches the update-to-date record of
deprecated batches and then removes them.

However, **once removed, deprecated batches are gone for good**. It is
advisable to backup your dataset before proceeding ([see
below](#why-not-remove-deprecated)).

Just in case,
[`deprecateBatches()`](https://motuswts.github.io/motus/reference/deprecateBatches.md)
will ask you if you are sure you want to remove the batches before
proceeding.

``` r
sql_motus <- deprecateBatches(sql_motus)
```

    You are about to permanently delete up to 6 deprecated batches from project-176.motus
    Continue? 

    1: Yes
    2: No

    Selection: 1

    ## Fetching deprecated batches
    ## Total deprecated batches: 6
    ## New deprecated batches: 0
    ##   232 deprecated rows deleted from runs
    ##   473 deprecated rows deleted from hits
    ##   780 deprecated rows deleted from activity
    ##   232 deprecated rows deleted from batchRuns
    ##   6 deprecated rows deleted from projBatch
    ##   6 deprecated rows deleted from batches
    ## Repacking data base to save space...
    ## Total deprecated batches removed: 6

After removal, you can see that the batches have been removed from the
data

``` r
tbl(sql_motus, "alltags") %>%
  filter(batchID %in% c(6000, 6001, 6002))
```

    ## # Source:   SQL [?? x 62]
    ## # Database: sqlite 3.51.1 [/home/runner/work/motus/motus/vignettes/articles/data/project-176.motus]
    ## # ℹ 62 variables: hitID <int>, runID <int>, batchID <int>, ts <dbl>, tsCorrected <lgl>,
    ## #   sig <dbl>, sigsd <dbl>, noise <dbl>, freq <dbl>, freqsd <dbl>, slop <dbl>,
    ## #   burstSlop <dbl>, done <int>, motusTagID <lgl>, ambigID <int>, port <chr>,
    ## #   nodeNum <chr>, runLen <int>, motusFilter <dbl>, bootnum <int>, tagProjID <int>,
    ## #   mfgID <chr>, tagType <chr>, codeSet <chr>, mfg <chr>, tagModel <chr>,
    ## #   tagLifespan <int>, nomFreq <dbl>, tagBI <dbl>, pulseLen <dbl>, tagDeployID <int>,
    ## #   speciesID <int>, markerNumber <chr>, markerType <chr>, tagDeployStart <dbl>, …

Also that the `deprecated` table now lists `removed` as 1.

``` r
tbl(sql_motus, "deprecated")
```

    ## # Source:   table<`deprecated`> [?? x 3]
    ## # Database: sqlite 3.51.1 [/home/runner/work/motus/motus/vignettes/articles/data/project-176.motus]
    ##   batchID batchFilter removed
    ##     <int>       <int>   <int>
    ## 1    6000           4       1
    ## 2    6001           4       1
    ## 3    6002           4       1
    ## 4    6003           4       1
    ## 5    6004           4       1
    ## 6    6005           4       1

## Why **not** remove deprecated batches?

In active projects it is a good idea to remove deprecated batches
routinely, to ensure your data is update to date and as accurate as
possible.

However, once removed, deprecated batches are gone for good. If you have
an analysis or publication based on older data versions, this analysis
is no longer repeatable as you no longer have the original batches.

It is therefore advisable to keep a copy of the database (i.e. the
`XXXX.motus` file) you need for a specific analysis backed up and static
(i.e. no updates and no removal of deprecated batches).

> **What Next?** [Explore all
> articles](https://motuswts.github.io/motus/articles/index.md)
