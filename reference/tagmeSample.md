# Create an in-memory copy of sample tags data

For running examples and testing out motus functionality, it can be
useful to work with sample data set. You can download the most
up-to-date copy of this data yourself (to `project-176.motus`) with the
username and password both "motus.sample".

## Usage

``` r
tagmeSample(db = "project-176.motus")
```

## Arguments

- db:

  Character. Name of sample data base to load. The sample data is
  "project-176.motus".

## Value

In memory version of the sample database.

## Details

`sql_motus <- tagme(176, new = TRUE)`

Or you can use this helper function to grab an in-memory copy bundled in
this package.

## Examples

``` r
# Explore the sample data
tags <- tagmeSample()
dplyr::tbl(tags, "activity")
#> # Source:   table<`activity`> [?? x 15]
#> # Database: sqlite 3.51.1 [:memory:]
#>    batchID motusDeviceID ant   hourBin numTags pulseCount numRuns numHits  run2
#>      <int>         <int> <chr>   <int>   <int>      <int>   <int>   <int> <int>
#>  1      53           486 1      400872       1         28       1       7     0
#>  2      53           486 1      401014       1         24       1       5     0
#>  3      53           486 1      401204       1         24       1       6     0
#>  4      53           486 -1     401014       1          8       1       2     1
#>  5      53           486 -1     401204       1         24       1       4     0
#>  6      53           486 2      401012       1         12       1       3     0
#>  7      53           486 2      401014       1         12       1       2     1
#>  8      53           486 2      401204       1         28       1       6     0
#>  9      53           486 3      400796       1         15       1       2     1
#> 10      53           486 3      400872       1         16       1       3     0
#> # ℹ more rows
#> # ℹ 6 more variables: run3 <int>, run4 <int>, run5 <int>, run6 <int>,
#> #   run7plus <int>, numGPSfix <int>
dplyr::tbl(tags, "alltags")
#> # Source:   table<`alltags`> [?? x 62]
#> # Database: sqlite 3.51.1 [:memory:]
#>     hitID runID batchID      ts tsCorrected   sig sigsd noise  freq freqsd  slop
#>     <int> <int>   <int>   <dbl>       <dbl> <dbl> <dbl> <dbl> <dbl>  <dbl> <dbl>
#>  1  45107  8886      53  1.45e9 1445858390.    52     0   -96     4      0  1e-4
#>  2  45108  8886      53  1.45e9 1445858429.    54     0   -96     4      0  1e-4
#>  3  45109  8886      53  1.45e9 1445858477.    55     0   -96     4      0  1e-4
#>  4  45110  8886      53  1.45e9 1445858516.    52     0   -96     4      0  1e-4
#>  5  45111  8886      53  1.45e9 1445858564.    49     0   -96     4      0  1e-4
#>  6 199885 23305      64  1.45e9 1445857924.    33     0   -96     4      0  1e-4
#>  7 199886 23305      64  1.45e9 1445857983.    41     0   -96     4      0  1e-4
#>  8 199887 23305      64  1.45e9 1445858041.    29     0   -96     4      0  1e-4
#>  9 199888 23305      64  1.45e9 1445858089.    41     0   -96     4      0  1e-4
#> 10 199889 23305      64  1.45e9 1445858147.    45     0   -96     4      0  1e-4
#> # ℹ more rows
#> # ℹ 51 more variables: burstSlop <dbl>, done <int>, motusTagID <int>,
#> #   ambigID <int>, port <chr>, nodeNum <chr>, runLen <int>, motusFilter <dbl>,
#> #   bootnum <int>, tagProjID <int>, mfgID <chr>, tagType <chr>, codeSet <chr>,
#> #   mfg <chr>, tagModel <chr>, tagLifespan <int>, nomFreq <dbl>, tagBI <dbl>,
#> #   pulseLen <dbl>, tagDeployID <int>, speciesID <int>, markerNumber <chr>,
#> #   markerType <chr>, tagDeployStart <dbl>, tagDeployEnd <dbl>, …
```
