# Report or claim ambiguous tag detections

A detections is "ambiguous" if the motus tag finder could not tell which
of several tags was detected, because they all produce the same signal
and were active at the same time. The motus tag finder uses tag
deployment and lifetime metadata to decide what tags to seek when, and
notices when it can't distinguish between two or more of them.
Detections of such tags during these periods of overlap are assigned a
negative motus tag ID that represents from 2 to 6 possible real motus
tags. The ambiguities might be real (i.e. two or more tags transmitting
the same signal and active at the same time), or due to errors in tag
registration or deployment metadata.

## Usage

``` r
clarify(src, id, from, to, all.mine = FALSE)
```

## Arguments

- src:

  SQLite connection. Result of `tagme(XXX)` or
  `DBI::dbConnect(RSQLite::SQLite(), "XXX.motus")`.

- id:

  if not missing, a vector of negative motus ambiguous tag IDs for which
  you wish to claim detections. If missing, all tags are claimed over
  any period specified by `from` and `to`.

- from:

  Character. If not missing, the start time for your claim to ambiguous
  detections of tag(s) `id`. If missing, you are claiming all detections
  up to `to`. `from` can be a numeric timestamp, or a character string
  compatible with
  [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html)

- to:

  Character. If not missing, the end time for your claim to ambiguous
  detections of tag(s) `id`. If missing, you are claiming all detections
  after `from`. `to` can be a numeric timestamp, or a character string
  compatible with
  [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html)

- all.mine:

  Logical. If TRUE, claim all ambiguous detections. In this case, `id`,
  `from` and `to` are ignored.

## Value

With no parameters, returns a summary data frame of ambiguous tag
detections

## Details

This function serves two purposes:

- called with only a database, it reports the numbers of ambiguous
  detections and what they could represent.

- called with `id`, it lets you claim some of the ambiguities as your
  own tag, so that in subsequent processing, they will appear to be
  yours.

This function does not (yet?) report your claim to motus.org

WARNING: you cannot undo a claim within a copy of the database. If
unsure, copy the .motus file first, then run `clarify` on only one copy.

If both `from` and `to` are missing, then all detections of ambiguous
tag(s) `id` are claimed.

Parameters `id`, `from`, and `to` are recycled to the length of the
longest item.

When you claim an ambiguous tag `T` for a period, any runs of `T` which
overlap that period at all are claimed entirely, even if they extend
beyond the period; i.e. runs are not split.

## Examples

``` r
if (FALSE) { # \dontrun{
s <- tagme(57)         # get the tag database for project 57
clarify(s)             # report on the ambiguous tag detections in s
clarify(all.mine = TRUE) # claim all ambiguous tag detections as mine
clarify(id = -57)      # claim all detections of ambiguous tag -57 as mine

clarify(id = c(-72, -88, -91), from = "2017-01-02", to = "2017-05-06")
# claim all detections of ambiguous tags -72, -88, and -91 from
#   January 2 through May 6, 2017, as mine
} # }
```
