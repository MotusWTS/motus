# Download motus tag detections to a database

This is the main motus function for accessing and updating your data.
This function downloads motus data to a local SQLite data base in the
name of `project-XXX.motus` or `RECIVER_NAME.motus`. If you are having
trouble with a particular data base timing out on downloads, see
[`srvTimeout()`](https://motuswts.github.io/motus/reference/srvTimeout.md)
for options.

## Usage

``` r
tagme(
  projRecv,
  update = TRUE,
  new = FALSE,
  dir = getwd(),
  countOnly = FALSE,
  forceMeta = FALSE,
  rename = FALSE,
  skipActivity = FALSE,
  skipNodes = FALSE,
  skipDeprecated = FALSE
)
```

## Arguments

- projRecv:

  Numeric. Project code from motus.org, *or* character receiver serial
  number.

- update:

  Logical. Download and merge new data (Default `TRUE`)?

- new:

  Logical. Create a new database (Default `FALSE`)? Specify `new = TRUE`
  to create a new local copy of the database to be downloaded.
  Otherwise, it assumes the database already exists, and will stop with
  an error if it cannot find it in the current directory. This is mainly
  to prevent inadvertent downloads of large amounts of data that you
  already have!

- dir:

  Character. Path to the folder where you are storing databases IF
  `NULL` (default), uses current working directory.

- countOnly:

  Logical. If `TRUE`, return only a count of items that would need to be
  downloaded in order to update the database (Default `FALSE`).

- forceMeta:

  Logical. If `TRUE`, re-download metadata for tags and receivers, even
  if we already have them.

- rename:

  Logical. If current SQLite database is of an older data version,
  automatically rename that database for backup purposes and download
  the newest version. If `FALSE` (default), user is prompted for action.

- skipActivity:

  Logical. Skip checking for and downloading `activity`? See
  [`?activity`](https://motuswts.github.io/motus/reference/activity.md)
  for more details

- skipNodes:

  Logical. Skip checking for and downloading `nodeData`? See
  [`?nodeData`](https://motuswts.github.io/motus/reference/nodeData.md)
  for more details

- skipDeprecated:

  Logical. Skip fetching list of deprecated batches stored in
  `deprecated`. See `?deprecateBatches()` for more details.

## Value

a SQLite Connection for the (possibly updated) database, or a data frame
of counts if `countOnly = TRUE`.

## See also

[`tellme()`](https://motuswts.github.io/motus/reference/tellme.md),
which is a synonym for `tagme(..., countOnly = TRUE)`

## Examples

``` r
if (FALSE) { # \dontrun{

# Create and update a local tag database for motus project 14 in the
# current directory

t <- tagme(14, new = TRUE)

# Update and open the local tag database for motus project 14;
# it must already exist and be in the current directory

t <- tagme(14)

# Update and open the local tag database for a receiver;
# it must already exist and be in the current directory

t <- tagme("SG-1234BBBK4567")

# Open the local tag database for a receiver, without
# updating it

t <- tagme("SG-1234BBBK4567", update = FALSE)

# Open the local tag database for a receiver, but
# tell 'tagme' that it is in a specific directory

t <- tagme("SG-1234BBBK4567", dir = "Projects/gulls")

# Update all existing project and receiver databases in the current working
# directory

tagme()
} # }
```
