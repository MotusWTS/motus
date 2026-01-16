# Chapter 3 - Accessing detections data

> In this chapter we’ll walk through the motus data format, downloading,
> exporting and updating your detections, as well as dealing with
> metadata.
>
> Some extra, more advanced topics *not* addressed in this chapter are
> available as supplementary articles.
>
> **Advanced Topics:**
>
> - [`motus` data base
>   variables](https://motuswts.github.io/motus/articles/database_variables.md)
> - [Working with GPS
>   points](https://motuswts.github.io/motus/articles/gps.md)

**Before downloading your detection data, please ensure that you have no
pending metadata issues on the [Motus website](https://motus.org/). Log
in and view the Data Issues page under Manage Data.**

This chapter will begin with an introduction to the structure of the
detections database, followed by instructions on how to download and
access the data. If you’re interested in a quick start, checkout the
[Getting Started](https://motuswts.github.io/motus/articles/motus.md)
article for a summary that includes how to download, select variables,
clean data, and export data.

## Data structure

Each tag detection database is stored as an SQLite file with the
extension ‘.motus’. The SQLite format was chosen because:

1.  it is **flexible**, allowing for many data formats.
2.  it is **accessible** from many software platforms (not just R).
3.  it is **appendable**, meaning the database can be created and
    updated on disk without having to read in and resave the entire
    contents. This will save time and computer memory when searching to
    see if any new detections are available for your project or
    receiver.

The .motus file contains a series of interrelated tables where data are
stored in a condensed format to save memory. The following tables are
included in your .motus file;

1.  **`activity`**: data related to radio activity for each hour period
    (`hourBin`) at each antenna, including a count of the number of
    short runs used in helping identify false detections.
2.  **`admInfo`**: internal table used to keep track of your the motus
    package used to create your motus file, and the data version.
3.  **`antDeps`**: metadata related to antenna deployments, e.g.,
    deployment height, angle, antenna type.
4.  **`batchRuns`**: metadata for runIDs and associated batchIDs
5.  **`batches`**: detection data for a given receiver and boot number.
6.  **`filters`**: metadata related to user created filters associated
    with the specified receiver.  
7.  **`gps`**: metadata related to Geographic Positioning System (GPS)
    position of receiver.
8.  **`hits`**: detection data at the level of individual hits.
9.  **`meta`**: metadata related to the project and datatype (tags
    vs. receivers) that are included in the .motus file
10. **`nodeData`**: data related to nodes by `batchID` and time (`ts`)
11. **`nodeDeps`**: metadata related to nodes
12. **`projAmbig`**: metadata related to what projects have ambiguous
    tag detections
13. **`projs`**: metadata related to projects, e.g., project name,
    principal investigator.
14. **`pulseCounts`**: number of radio pulses measured on each antenna
    over each hour period (`hourBin`).
15. **`recvDeps`**: metadata related to receiver deployments, e.g.,
    deployment date, location, receiver characteristics.
16. **`recvs`**: metadata related to receiver serial number and
    associated Motus deviceID
17. **`runs`**: detection data associated with a run (continuous
    detections of a unique tag on a given receiver).
18. **`runsFilters`**: a list of runIDs associated with user created
    filters and assigned probabilities.  
19. **`species`**: metadata related to species, e.g., unique identifier,
    scientific name, common name.
20. **`tagAmbig`**: metadata related to ambiguous tags, e.g., ambigID
    and associated motusTagID
21. **`tagDeps`**: metadata related to tag deployments, e.g., deployment
    date, location, and species.
22. **`tagProp`**: metadata related to custom deployment properties
    entered by the principal investigator (e.g. body weight).
23. **`tags`**: metadata related to tags, e.g., unique identifier, tag
    characteristics (e.g., burst interval).

In addition to these tables, there are also ‘virtual’ tables or ‘views’,
which have been created through queries that merge data from the various
tables into a single convenient ‘view’ that contains all of the fields
you are likely to need. The following views are currently included in
each .motus file:

1.  **`allambigs`**: lists in long-data format each motusTagID (up to 6)
    associated with each negative ambigID.
2.  **`alltags`**: provides the full detection data for all tags, and
    all ambiguous (duplicate) tags, associated with your project.
    Ambiguous detections are repeated for each motusTagID represented by
    each ambigID.  
3.  **`alltagsGPS`**: same as `alltags` but includes GPS latitude,
    longitude and altitude (much slower to load on large databases).

Because the file is a SQLite database, all of the `dplyr` functions can
be used to filter and summarize the .motus database, without needing to
first save the data as a *flat* file (a typical two-dimensional
dataframe). The SQL format is very advantageous when you have a large
file – the queries using SQL will be substantially faster than those
done on a flat dataframe.

## Database types

There are two types of tag detection databases available for download:

1.  **receiver database**: includes all detections of any registered
    tags from a single receiver. A receiver database has a name like
    SG-1234BBBK5678.motus, where the name is the serial number of the
    receiver.

2.  **project database**: includes all detections of your registered
    tags from across the Motus network. A tag project database has a
    name like project-123.motus, where the number is the Motus project
    ID.

These two databases correspond to the basic model of data sharing:

1.  you get all detections of *anyone’s* tags by *your* receivers (i.e.,
    one receiver tag database for each receiver you deploy).

2.  you get all detections of *your* tags by *anyone’s* receivers (i.e.,
    one project tag database for each of your Motus projects).

## Load relevant R packages

Before we begin working with data, we need to load the required packages
for this chapter. If you have not yet *installed* these packages (from
github and CRAN) then please return to [Chapter 2 - Installing
Packages](https://motuswts.github.io/motus/articles/02-installing-packages.md).

``` r
library(motus)
library(lubridate)
library(dplyr)
```

## Set system environment

Set the system environment time zone to Greenwich Mean Time (UTC), to
ensure that you are always working in UTC. This is a very important
step, and should be part of every working session. If you fail to do
this, then two problems can arise. Times are stored in the Motus
database in UTC, and if you do not keep your environment in UTC, then
they can be inadvertently changed during import. Second, if tags have
been detected across multiple time zones, then they can also
inadvertently be changed.

``` r
Sys.setenv(TZ = "UTC")
```

## Downloading tag detections

To import tag detections for your project or receiver, you need a
numerical project id or character scalar receiver serial number.

The success of the Motus network is dependent on the timely upload of
detection data from receivers, and on the maintenance of accurate and
up-to-date tag and receiver metadata by collaborators. After downloading
your data from the Motus server, users are encouraged to [update
detections](#updating-detections) and [update
metadata](#updating-metadata) each time they run an analysis, because
collaborators can add detection data and metadata at any time, and these
could influence the completeness of your own detections data.

Be warned that large datasets can take some time (sometimes a few hours)
to download from the Motus server when downloading for the first time.
After the initial download, loading a .motus file into R and updating
for any new data will be near instantaneous, unless there is a lot of
new data.

### Download data for a project for the *first time*

All data downloads are completed using the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function in the `motus` R package. This function will save an SQLite
database to your computer with the extension “.motus”; see further
details on [data structure](#data-structure). The following parameters
are available for the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function:

- **`projRecv`**: integer project number OR a character vector receiver
  serial number.
- **`new`**: if set to `TRUE`, it will create a new empty .motus file in
  your local directory. Do not use this parameter or set it to `FALSE`
  if you already have a .motus file.
- **`update`**: if set to `TRUE`, will download all available data to
  your existing .motus file. Must be set to `TRUE` on your first data
  download and any subsequent downloads if you wish to check for new
  data. Set to `FALSE` if you do not wish to check for new data (e.g.,
  if working offline).
- **`dir`**: Your .motus data is automatically saved to your working
  directory, unless you specify a different location using this
  parameter.
- **`forceMeta`**: if set to `TRUE`, it will force an update of metadata
  to an existing .motus file.

Throughout these articles we use [sample
data](https://motuswts.github.io/motus/articles/01-introduction.html#sample-datasets)
which have been assigned to project 176.

Let’s get started by downloading data by project - this will include all
detections of your tags on any receiver.

Note that when downloading data from the Motus server for the **first
time**, you must specify `new = TRUE` and `update = TRUE`. You will also
be prompted to [login](#user-authentication).

**Unless the directory that you want your data saved in is stated
explicitly within the function call, data will be downloaded to the
current working directory.**

Lets start by determining what our working directory is so we know where
our file will be saved.

``` r
getwd()
```

As this is the first time you are downloading data for project 176, set
`projRecv = 176`, `new = TRUE` and `update = TRUE`. This will create a
`.motus` file in your current working directory, which was shown above
using [`getwd()`](https://rdrr.io/r/base/getwd.html). This will also
create an SQL object in your R environment called `sql_motus`

``` r
sql_motus <- tagme(projRecv = 176, new = TRUE)
```

Alternatively you can specify a different location to save the data by
entering your preferred filepath. In this example we save to our data
folder using the `dir` argument. Note that `./` simply means ‘relative
to the current folder’ (shown by
[`getwd()`](https://rdrr.io/r/base/getwd.html)).

``` r
sql_motus <- tagme(projRecv = 176, new = TRUE, dir = "./data/")
```

> **Note:** You’ll need to use the **username** `motus.sample` and the
> **password** `motus.sample` to access this data (see [login](#login)
> for more details)!

Using [`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
as shown above will download a file to your working or specified
directory called `project-176.motus` for the sample data (the number in
the file name corresponds to the project number). The progress of the
download process should print on the console; if you are not seeing it,
try scrolling down your screen while
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md) is
running.

In the event that your connection to the Motus server fails prior to a
complete download (e.g., due to a poor internet connection), use
`tagme(proj.num)` to continue the download from where it left off,
ensuring you specify a directory if it is saved outside the working
directory.

### User Authentication

#### Login

The first time you call a function using the Motus R package, you will
be asked to enter your motus.org username and password in the R console
to authenticate your access to project data. This will only happen once
per R session. If you do not have a Motus username and password, you can
[sign up](https://motus.org/data/user/new) to get one. Permission to
access project data will then be granted by Motus staff or the project
principal investigator.

When accessing the sample data you will need to login using username and
password ‘motus.sample’ in the R console when prompted by the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function (see the [Download](#download) section above). It will look
like this:

![](images/SampleLogin.png)

To download data for one of your own projects, change the project number
to that of your own project in the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md) call,
and enter your own Motus login/password in the R console when prompted.
If you are already logged in as the sample data user, you will need to
first logout to download your own data.

#### Logging out

Once you are logged in under one user account, you will not be able to
access data from another account. If you need to logout of the current
account to access other data, you will need to use the logout function.

``` r
motusLogout()
```

### Download data for a receiver for the *first time*

We could also download data by receiver through the same process as
described above. This will provide you with all detections of any tags
on the specified receiver. As there are no receivers registered to
sample project 176, **this call will not work**. If you have a receiver
registered to your own project, replace the receiver serial number in
the tagme call below with the serial number for your own receiver,
ensuring that you are logged in using your own
[credentials](#user-authentication).

``` r
proj.num <- "SG-123BBBK1234"
sql_motus <- tagme(projRecv = proj.num, new = TRUE)
```

This will download a file to your working directory named
`SG-123BBBK1234.motus`.

Some users may wish to work directly with the .motus SQLite file.
However, since many users are more familiar with a ‘flat’ dataframe
format, instructions to view the the data as a flat dataframe within R,
and on how to export the flat file to .csv or .rds format, are included
below.

### Downloading multiple receivers at the same time

If you have a large number of receivers in your project, and wish to get
receiver specific data for each one, rather than downloading them one by
one as above, we can download them with a simple loop. Note that since
the sample project doesn’t have any receivers associated with it, this
script will not result in a download but you can try it with your own
project if you have receivers.

``` r
# get a copy of the metadata only
sql_motus <- tagme(176, new = TRUE, update = FALSE, dir = "./data/")
metadata(sql_motus, 176)
tbl_recvDeps <- tbl(sql_motus, "recvDeps")

df_serno <- tbl_recvDeps %>% 
  filter(projectID == 176) %>% 
  select(serno) %>% 
  distinct() %>% 
  collect() %>% 
  as.data.frame()

# loop through each receiver (may take a while!)
for (row in 1:nrow(df.serno)) {
  tagme(df.serno[row, "serno"], dir = "./data/", new = TRUE)
}

# Note you can remove the dir argument if you want to save it to your working
# directory, just make sure that you use the same directory in both calls
```

You can also create a list of receivers you’d like to download if you
don’t want to download project-wide receivers:

``` r
# create list of receivers you'd like to download
df.serno <- c("SG-AB12RPI3CD34", "SG-1234BBBK4321")

# loop through each receiver (may take a while!), and save to the working directory
for (k in 1:length(df.serno)) {
  tagme(df.serno[k], new = TRUE)
}

# loop through each receiver (may take a while!), and save to a specified directory
for (k in 1:length(df.serno)) {
  tagme(df.serno[k], dir = "./data/", 
        new = TRUE)
}
```

### Updating all `.motus` files within a directory

Once you have .motus files, you can also update them all by simply
calling the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function but leaving all arguments blank, apart from the directory:

``` r
# If you have them saved your working directory:
tagme()

# If you have them saved in a different directory:
tagme(dir = "./data/")
```

### Accessing downloaded detection data

Now that we’ve downloaded our data as an SQLite database and loaded it
into an R object called `sql_motus`, we want to access the tables stored
within. Detailed descriptions of all the tables stored in the .motus
file can be found in the [Data structure](#data-structure) section.

You can also view the list of tables, and variables contained within
those tables, using the `DBI` and `RSQLite` packages (these are
automatically installed when you install `motus`).

``` r
library(DBI)
library(RSQLite)

# specify the filepath where your .motus file is saved, and the file name.
file.name <- dbConnect(SQLite(), "./data/project-176.motus") 

# get a list of tables in the .motus file specified above.
dbListTables(file.name) 
```

    ##  [1] "activity"    "activityAll" "admInfo"     "allambigs"   "allruns"    
    ##  [6] "allrunsGPS"  "alltags"     "alltagsGPS"  "antDeps"     "batchRuns"  
    ## [11] "batches"     "clarified"   "deprecated"  "filters"     "gps"        
    ## [16] "gpsAll"      "hits"        "meta"        "nodeData"    "nodeDeps"   
    ## [21] "projAmbig"   "projBatch"   "projs"       "recvDeps"    "recvs"      
    ## [26] "runs"        "runsFilters" "species"     "tagAmbig"    "tagDeps"    
    ## [31] "tagProps"    "tags"

``` r
# get a list of variables in the "species" table in the .motus file.
dbListFields(file.name, "species") 
```

    ## [1] "id"         "english"    "french"     "scientific" "group"     
    ## [6] "sort"

The *virtual* table `alltags` contains the detection data, along with
most metadata variables that users need from the various underlying
`.motus` tables. We access the tables using the
[`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) function from
the `dplyr` package which we installed in [Chapter
2](https://motuswts.github.io/motus/articles/02-installing-packages.md)
and loaded at the [start of this chapter](#load-relevant-r-packages).

For example, retrieve the virtual `alltags` table from our `sql_motus`
SQLite file.

``` r
tbl.alltags <- tbl(sql_motus, "alltags")
```

We now have a new `tbl.alltags` object in R. The underlying structure of
these tables is a list of length 2:

``` r
str(tbl.alltags)
```

    ## List of 2
    ##  $ src       :List of 2
    ##   ..$ con  :Formal class 'SQLiteConnection' [package "RSQLite"] with 8 slots
    ##   .. .. ..@ ptr                :<externalptr> 
    ##   .. .. ..@ dbname             : chr "/home/runner/work/motus/motus/vignettes/articles/data/project-176.motus"
    ##   .. .. ..@ loadable.extensions: logi TRUE
    ##   .. .. ..@ flags              : int 70
    ##   .. .. ..@ vfs                : chr ""
    ##   .. .. ..@ ref                :<environment: 0x556dfdcb51e0> 
    ##   .. .. ..@ bigint             : chr "integer64"
    ##   .. .. ..@ extended_types     : logi FALSE
    ##   ..$ disco: NULL
    ##   ..- attr(*, "class")= chr [1:4] "src_SQLiteConnection" "src_dbi" "src_sql" "src"
    ##  $ lazy_query:List of 5
    ##   ..$ x         : 'dbplyr_table_path' chr "`alltags`"
    ##   ..$ vars      : chr [1:62] "hitID" "runID" "batchID" "ts" ...
    ##   ..$ group_vars: chr(0) 
    ##   ..$ order_vars: NULL
    ##   ..$ frame     : NULL
    ##   ..- attr(*, "class")= chr [1:3] "lazy_base_remote_query" "lazy_base_query" "lazy_query"
    ##  - attr(*, "class")= chr [1:5] "tbl_SQLiteConnection" "tbl_dbi" "tbl_sql" "tbl_lazy" ...

The first part of the list, `src`, is a list that provides details of
the SQLiteConnection, including the directory where the database is
stored. The second part is a list that includes the underlying table.
Thus, the R object `alltags` is a *virtual* table that stores the
database structure and information required to connect to the underlying
data in the `.motus` file. As stated above, the advantage of storing the
data in this way is that it saves memory when accessing very large
databases, and functions within the `dplyr` package can be used to
manipulate and summarize the tables before collecting the results into a
typical ‘flat’ format dataframe.

If you want to use familiar functions to get access to components of the
underlying data frame, then use the
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html)
function. For example, to look at the names of the variables in the
`alltags` table:

``` r
tbl.alltags %>% 
  collect() %>%
  names() # list the variable names in the table
```

    ##  [1] "hitID"          "runID"          "batchID"        "ts"            
    ##  [5] "tsCorrected"    "sig"            "sigsd"          "noise"         
    ##  [9] "freq"           "freqsd"         "slop"           "burstSlop"     
    ## [13] "done"           "motusTagID"     "ambigID"        "port"          
    ## [17] "nodeNum"        "runLen"         "motusFilter"    "bootnum"       
    ## [21] "tagProjID"      "mfgID"          "tagType"        "codeSet"       
    ## [25] "mfg"            "tagModel"       "tagLifespan"    "nomFreq"       
    ## [29] "tagBI"          "pulseLen"       "tagDeployID"    "speciesID"     
    ## [33] "markerNumber"   "markerType"     "tagDeployStart" "tagDeployEnd"  
    ## [37] "tagDepLat"      "tagDepLon"      "tagDepAlt"      "tagDepComments"
    ## [41] "tagDeployTest"  "fullID"         "deviceID"       "recvDeployID"  
    ## [45] "recvDeployLat"  "recvDeployLon"  "recvDeployAlt"  "recv"          
    ## [49] "recvDeployName" "recvSiteName"   "isRecvMobile"   "recvProjID"    
    ## [53] "recvUtcOffset"  "antType"        "antBearing"     "antHeight"     
    ## [57] "speciesEN"      "speciesFR"      "speciesSci"     "speciesGroup"  
    ## [61] "tagProjName"    "recvProjName"

If you want access to GPS data you can either use the `alltagsGPS` view,
or, after filtering your data (see [Chapter 5 - Data
cleaning](https://motuswts.github.io/motus/articles/05-data-cleaning.md)
and the article [In-depth detections
filtering](https://motuswts.github.io/motus/articles/filtering.md)) you
can use the
[`getGPS()`](https://motuswts.github.io/motus/reference/getGPS.md)
function (see [Working with GPS
points](https://motuswts.github.io/motus/articles/gps.md)).

### Converting to flat data

To convert the `alltags` view or other table in the .motus file into a
typical ‘flat’ format, i.e., with every record for each field filled in,
use the
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html) and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
functions. The output can then be further manipulated, or used to
generate a RDS file of your data for archiving or export.

``` r
df.alltags <- tbl.alltags %>% 
  collect() %>% 
  as.data.frame()
```

Now we have flat data of the alltags table called `df.alltags`. We can
look at some metrics of the file:

``` r
names(df.alltags)     # field names
str(df.alltags)       # structure of your data fields
head(df.alltags)      # prints the first 6 rows of your df to the console
summary(df.alltags)   # summary of each column in your df
```

Note that the format of the time stamp (`ts`) field is numeric and
represents seconds since 1 January 1970. We recommend that when you
transform your tables into flat dataframes, that you format the time
stamp using the `lubridate` package. This results in the `time` column
in date/time format, leaving the `ts` column as numeric. *Note:* By
default,
[`as_datetime()`](https://lubridate.tidyverse.org/reference/as_date.html)
uses an origin of 1 January 1970 and UTC as the timezone, exactly what
we want!

``` r
df.alltags <- tbl.alltags %>% 
  collect() %>% 
  as.data.frame() %>%     # for all fields in the df (data frame)
  mutate(time = as_datetime(ts))

# the tz = "UTC" is not necessary here, provided you have set your system time to UTC
# ... but it serves as a useful reminder!
```

Note that time stamps can only be manipulated in this way *after*
collecting the data into a flat dataframe. Throughout these articles, we
use `ts` for numeric time stamps and `time` for date/time formatted time
stamps.

If you want to load only part of your entire virtual table (e.g. certain
fields, certain tags, or all tags from a specified project or species),
you can use `dplyr` functions to filter the data before collecting into
a dataframe. Some examples are below:

1.  To select certain variables:

``` r
# to grab a subset of variables, in this case a unique list of Motus tag IDs at
# each receiver and antenna.
df.alltagsSub <- tbl.alltags %>%
  select(recv, port, motusTagID) %>%
  distinct() %>% 
  collect() %>% 
  as.data.frame() 
```

2.  To select certain tag IDs:

``` r
# filter to include only motusTagIDs 16011, 23316
df.alltagsSub <- tbl.alltags %>%
  filter(motusTagID %in% c(16011, 23316)) %>% 
  collect() %>% 
  as.data.frame() %>%    
  mutate(time = as_datetime(ts))    
```

3.  To select a specific species:

``` r
# filter to only Red Knot (using speciesID)
df.4670 <- tbl.alltags %>%
  filter(speciesID == 4670) %>%  
  collect() %>% 
  as.data.frame() %>%    
  mutate(time = as_datetime(ts))  

# filter to only Red Knot (using English name)
df.redKnot <- tbl.alltags %>%
  filter(speciesEN == "Red Knot") %>%   
  collect() %>% 
  as.data.frame() %>%    
  mutate(time = as_datetime(ts))    
```

Using `dplyr`, your virtual table can also be summarized before
converting to a flat file. For example, to find the number of different
detections for each tag at each receiver:

``` r
df.detectSum <- tbl.alltags %>% 
  count(motusTagID, recv) %>%
  collect() %>%
  as.data.frame() 
```

In later chapter(s) we will show you additional ways of summarizing and
working with your data.

## Exporting detections

A good workflow is to create a script that deals with all your data
issues (as described in later chapters), and then saves the resulting
‘flat’ dataframe to CSV or RDS for re-use. If you do this, you can
quickly start an analysis or visualization session from a known (and
consistent) starting point. We use an .rds file, which preserves all of
the associated R data structures (such as time stamps).

``` r
saveRDS(df.alltags, "./data/df_alltags.rds")  
```

Some users may also want to export the flat dataframe into a .csv file
for analysis in other programs. This can easily be done with the
following code. Note that it **does not** preserve time stamps:

``` r
write.csv(df.alltags, "./data/df_alltags.csv")
```

## Updating a database

### Updating detections

As you or other users upload data to our server, you may have additional
tag detections that weren’t present in your initial data download. Since
the `.motus` file is a SQLite database, you can update your existing
file with any newly available data, rather than doing a complete new
download of the entire database. To open and update a detections
database that already exists (has been downloaded previously), we use
the [`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function but set `new = FALSE`:

``` r
sql_motus <- tagme(projRecv = 176, dir = "./data/") 
```

    ## Checking for new data in project 176

    ## Updating metadata

    ## activity:     1 new batch records to check

    ## batchID  1977125 (#     1 of      1): got    156 activity records

    ## Downloaded 156 activity records

    ## nodeData:     0 new batch records to check

    ## Fetching deprecated batches

    ## Total deprecated batches: 6
    ## New deprecated batches: 0

If you are working offline, and simply want to open an already
downloaded database without connecting to the server to update, use
`new = FALSE` and `update = FALSE`:

``` r
# use dir = to specify a directory
sql_motus <- tagme(projRecv = 176, update = FALSE, dir = "./data")
```

### Checking for new detections

To check if new data are available for your project or receiver without
downloading the data, you can use the
[`tellme()`](https://motuswts.github.io/motus/reference/tellme.md)
function, which returns a list with:

- **`numHits`**: number of new tag detections.
- **`numBytes`**: approximate uncompressed size of data transfer
  required, in megabytes.
- **`numRuns`**: number of runs of new tag detections, where a run is a
  series of continuous detections for a tag on a given antenna.
- **`numBatches`**: number of batches of new data.
- **`numGPS`**: number of GPS records of new data.

The following assumes that a local copy of the database already exists:

``` r
tellme(projRecv = 176)                    # If db is in the working directory
tellme(projRecv = 176, dir = "./data/")   # To specify a different directory
```

To check how much data is available for a project but you *do not* have
a database for it, use the ‘new’ parameter:

``` r
tellme(projRecv = 176, new = TRUE)
```

### Updating metadata

Tag and receiver metadata are automatically merged with tag detections
when data are downloaded. However, if metadata have been updated since
your initial download, you can force re-import of the metadata when
updating a database by running:

``` r
sql_motus <- tagme(projRecv = 176, forceMeta = TRUE)
```

## Import full tag and receiver metadata

When you use
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md) to
download or update your .motus file, you are provided with the metadata
for:

1.  any tags registered to your project which have detections;
2.  tags from other projects which are associated with ambiguous
    detections (see [Chapter 5 - Data
    Cleaning](https://motuswts.github.io/motus/articles/05-data-cleaning.md)
    in your data;
3.  receivers that your tags and any ambiguous tags were detected on.

In many instances, you will want access to the full metadata for all
tags and receivers across the network, e.g., to determine how many of
your deployed tags were not detected, or to plot the location of
stations with and without detections. The
[`metadata()`](https://motuswts.github.io/motus/reference/metadata.md)
function can be used to add the complete Motus metadata to your `.motus`
file. The
[`metadata()`](https://motuswts.github.io/motus/reference/metadata.md)
function only needs to be run once, but we suggest that you re-import
the metadata occasionally to ensure that you have the most recent and
up-to-date information.

Running the
[`metadata()`](https://motuswts.github.io/motus/reference/metadata.md)
function as follows will add the appropriate metadata from across the
network (all tags and all receivers) to the `recvDeps` and `tagDeps`
tables in your .motus file:

``` r
# access all tag and receiver metadata for all projects in the network.
metadata(sql_motus) 
```

Alternatively, you can load metadata for a specific project(s) using:

``` r
# access tag and receiver metadata associated with project 176
metadata(sql_motus, projectIDs = 176) 

# access tag and receiver metadata associated with projects 176 and 1
metadata(sql_motus, projectIDs = c(176, 1)) 
```

## Ensure that you have the correct database version

When you call the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function to load the sqlite database, the version of the R package used
to download the data is stored in an `admInfo` table. Over time, changes
will be made to the functionality of the R package that may require
adding new tables, views or fields to the database. If your version of
the database does not match the version of the R package, some of the
examples contained in these articles may not work. The following call
will check that your database has been updated to the version matching
the current version of the `motus` R package. If your database does not
match the most current version of the R package, use
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md) with
`update = TRUE` to update your database to the correct format. Refer to
[Troubleshooting](https://motuswts.github.io/motus/articles/troubleshooting.md)
if the
[`checkVersion()`](https://motuswts.github.io/motus/reference/checkVersion.md)
call returns a warning.

``` r
checkVersion(sql_motus)
```

## R object naming convention

Throughout this chapter and the rest of the articles, we name R objects
according to their structure and the source of the data contained in the
object. So, SQLite objects will be prefixed with `sql.`, virtual table
objects will be prefixed with `tbl.`, and dataframe objects will be
prefixed with `df.`; the rest of the name will include the name of the
.motus table that the data originates from.

The following code assumes you have already downloaded the sample data
and do not need to update it; if you have not downloaded the data, see
the section on [downloading data for the first time](#download) for
instructions on initial download.

``` r
# SQLite R object, which links to the .motus file:
sql_motus <- tagme(176, dir = "./data")  

# virtual table object of the alltags table in the sample.motus file:
tbl.alltags <- tbl(sql_motus, "alltags")  
df.alltags <- tbl.alltags %>%
                collect() %>%
                as.data.frame() %>% # dataframe ("flat") object of alltags table
                mutate(time = as_datetime(ts))              
```

> **Next** [Chapter 4 - Project
> Deployments](https://motuswts.github.io/motus/articles/04-deployments.md)
> ([Explore all
> articles](https://motuswts.github.io/motus/articles/index.md))
