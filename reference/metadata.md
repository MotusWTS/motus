# Update all metadata

Updates the entire metadata for receivers and tags from Motus server.
Contrary to
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md), this
function retrieves the entire set of metadata for tags and receivers,
and not only those pertinent to the detections in your local file.

## Usage

``` r
metadata(src, projectIDs = NULL, replace = TRUE, delete = FALSE)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- projectIDs:

  optional integer vector of Motus projects IDs for which metadata
  should be obtained; default: NULL, meaning obtain metadata for all
  tags and receivers that your permissions allow.

- replace:

  logical scalar; if TRUE (default), existing data replace the existing
  metadata with the newly acquired ones.

- delete:

  logical scalar; Default = FALSE. if TRUE, the entire metadata tables
  are cleared (for all projects) before re-importing the metadata.

## See also

[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
provides an option to update only the metadata relevant to a specific
project or receiver file.

## Examples

``` r
# Download sample project 176 to .motus database (username/password are "motus.sample")
if (FALSE) sql_motus <- tagme(176, new = TRUE) # \dontrun{}

# Or use example data base in memory
sql_motus <- tagmeSample()
                   
# Add extended metadata to your file
if (FALSE) metadata(sql_motus) # \dontrun{}
  
# Access different metadata tables
library(dplyr)
tbl(sql_motus, "species")
#> # Source:   table<`species`> [?? x 6]
#> # Database: sqlite 3.51.1 [:memory:]
#>       id english                french                    scientific group  sort
#>    <int> <chr>                  <chr>                     <chr>      <chr> <int>
#>  1  4180 Semipalmated Plover    Pluvier semipalmé         Charadriu… BIRDS    NA
#>  2  4670 Red Knot               Bécasseau maubèche        Calidris … BIRDS    NA
#>  3  4680 Sanderling             Bécasseau sanderling      Calidris … BIRDS    NA
#>  4  4690 Semipalmated Sandpiper Bécasseau semipalmé       Calidris … BIRDS    NA
#>  5  4760 White-rumped Sandpiper Bécasseau à croupion bla… Calidris … BIRDS    NA
#>  6  4780 Pectoral Sandpiper     Bécasseau à poitrine cen… Calidris … BIRDS    NA
#>  7  4820 Dunlin                 Bécasseau variable        Calidris … BIRDS    NA
#>  8  4980 American Woodcock      Bécasse d'Amérique        Scolopax … BIRDS    NA
#>  9 15560 Gray-cheeked Thrush    Grive à joues grises      Catharus … BIRDS    NA
#> 10 19050 White-crowned Sparrow  Bruant à couronne blanche Zonotrich… BIRDS    NA
tbl(sql_motus, "projs")
#> # Source:   table<`projs`> [?? x 5]
#> # Database: sqlite 3.51.1 [:memory:]
#>      id name                            label tagsPermissions sensorsPermissions
#>   <int> <chr>                           <chr>           <int>              <int>
#> 1    47 Red Knot staging and migration… Niles              NA                 NA
#> 2    57 Selva Colombia                  Selva              NA                 NA
#> 3    82 Maine - American Woodcock       RBro…              NA                 NA
#> 4   146 Neonicotinoid insecticides and… NEON…              NA                 NA
#> 5   176 Sample Data                     Samp…              NA                 NA
tbl(sql_motus, "tagDeps")
#> # Source:   table<`tagDeps`> [?? x 24]
#> # Database: sqlite 3.51.1 [:memory:]
#>    tagID deployID projectID    tsStart      tsEnd deferSec speciesID markerType
#>    <int>    <int>     <int>      <dbl>      <dbl>    <dbl>     <int> <chr>     
#>  1 10811     1077        47 1414479600 1438585200        0      4670 metal band
#>  2 16011     1798       176 1438515600 1450352400        0      4690 metal band
#>  3 17357     1818       176 1439277600 1451114400        0      4760 metal band
#>  4 16035     1823       176 1439371200 1451208000        0      4690 metal band
#>  5 16036     1824       176 1439371200 1451208000        0      4690 metal band
#>  6 16037     1825       176 1439807400 1451644200        0      4690 metal band
#>  7 16038     1826       176 1439807400 1451644200        0      4690 metal band
#>  8 16039     1827       176 1439804400 1451641200        0      4690 metal band
#>  9 16044     1832       176 1439362800 1451199600        0      4760 metal band
#> 10 16047     1839       176 1441908000 1457632800        0      4670 metal band
#> # ℹ more rows
#> # ℹ 16 more variables: markerNumber <chr>, sex <chr>, age <chr>,
#> #   latitude <dbl>, longitude <dbl>, elevation <dbl>, comments <chr>,
#> #   test <int>, attachment <chr>, tsStartCode <chr>, tsEndCode <chr>,
#> #   bandNumber <chr>, id <int>, bi <int>, fullID <chr>, status <chr>
# Etc.
  
```
