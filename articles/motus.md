# Get started

This is a quick introduction to downloading Motus data. Definitely check
out the various [articles](https://motuswts.github.io/motus/index.md)
for more details!

Let’s get started by loading the packages we’ll use (see also [Chapter
2 - Installing
packages](https://motuswts.github.io/motus/articles/02-installing-packages.md).)

``` r
library(motus)
library(dplyr)
library(lubridate)
```

Now we’ll download some data. Here we’re downloading project 176 (sample
data, use user name and password ‘motus.sample’). You can use your own
project number or receiver name.

We use the
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
function to download the data

``` r
sql_motus <- tagme(176, dir = "./data/")
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

[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)
includes several options. Here we’re using:

- `new = FALSE` means the data base already exists, if it doesn’t,
  change `FALSE` to `TRUE`
- `dir = "./data/"` means the data base will be stored in the `data`
  folder inside your current working directory

[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md) stores
a `project-176.motus` SQLite data base in `./data/`.

We can access parts of the data base by referencing the SQL object we
created, `sql_motus`

Here, we’ll retrieve the `alltags` view from the SQLite database using
the [`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) function
from the `dplyr` package

``` r
tbl_alltags <- tbl(sql_motus, "alltags")
```

Next, we can convert this to a data frame (a flat file; see [Converting
to flat data in Chapter
3](https://motuswts.github.io/motus/articles/03-accessing-data.html#converting-to-flat-data))

Convert to flat
([`collect()`](https://dplyr.tidyverse.org/reference/compute.html)) and
create a date/time column `time` from the numeric timestamps, `ts`.

``` r
df_alltags <- tbl_alltags %>%
  collect() %>%
  mutate(time = as_datetime(ts))
```

If you want to save this flat file, you can export as RDS (see
[Exporting detections in Chapter
3](https://motuswts.github.io/motus/articles/03-accessing-data.html#exporting-detections))

``` r
saveRDS(df_alltags, "my_motus_data.rds")
```

Use caution when producing a flat file as using the full suite of fields
can use a lot of memory. This can slow R down considerably when dealing
with large datasets.

## Workflow summary

For your own data we suggest creating a script (or scripts) with the
following workflow:

1.  Download/update your data (see [Chapter 2 - Installing
    packages](https://motuswts.github.io/motus/articles/02-installing-packages.md),
    [Chapter 3 - Accessing detections
    data](https://motuswts.github.io/motus/articles/03-accessing-data.md))
2.  Select variables of interest for the table you are working with
    (typically `alltags`) (see [Chapter 3 - Accessing detections
    data](https://motuswts.github.io/motus/articles/03-accessing-data.md),
    [Chapter 4 - Tag and receiver
    deployments](https://motuswts.github.io/motus/articles/04-deployments.md))
3.  Initial cleaning (see [Chapter 4 - Tag and receiver
    deployments](https://motuswts.github.io/motus/articles/04-deployments.md)
    and [Chapter 5 - Data
    cleaning](https://motuswts.github.io/motus/articles/05-data-cleaning.md))
4.  Output the resulting data as an .rds file (see [Exporting detections
    in Chapter
    3](https://motuswts.github.io/motus/articles/03-accessing-data.html#exporting-detections)).
    We suggest using RDS instead of CSV, because the RDS format
    preserves the underlying structure of the data (e.g. times stay as
    times). If you want to export your data to another program, then a
    CSV format might be preferred.

> **What next?** Check out the walkthrough starting with [Chapter 1 -
> Introduction](https://motuswts.github.io/motus/articles/01-introduction.md)
> ([Explore all
> articles](https://motuswts.github.io/motus/articles/index.md))
