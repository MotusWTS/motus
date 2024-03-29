% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/siteSum.R
\name{siteSum}
\alias{siteSum}
\title{Summarize and plot detections of all tags by site}
\usage{
siteSum(data, units = "hours")
}
\arguments{
\item{data}{a selected table from .motus data, eg. "alltagsGPS", or a
data.frame of detection data including at a minimum variables for
motusTagID, sig, recvDeployLat, recvDeployLon, recvDeployName, ts, gpsLat,
and gpsLon}

\item{units}{units to display time difference, defaults to "hours", options
include "secs", "mins", "hours", "days", "weeks"}
}
\value{
a data.frame with these columns:
\itemize{
\item site: site
\item first_ts: time of first detection at specified site
\item last_ts: time of last detection at specified site
\item tot_ts: total amount of time between first and last detection at specified site, output in specified unit (defaults to "hours")
\item num.tags: total number of unique tags detected at specified site
\item num.det: total number of tag detections at specified site
}
}
\description{
Creates a summary of the first and last detection at a site, the length of
time between first and last detection, the number of tags, and the total
number of detections at a site.  Plots total number of detections across all
tags, and total number of tags detected at each site.
}
\examples{
# Download sample project 176 to .motus database (username/password are "motus.sample")
\dontrun{sql_motus <- tagme(176, new = TRUE)}

# Or use example data base in memory
sql_motus <- tagmeSample()

# convert sql file "sql_motus" to a tbl called "tbl_alltags"
library(dplyr)
tbl_alltags <- tbl(sql_motus, "alltagsGPS") 

# convert the tbl "tbl_alltags" to a data.frame called "df_alltags"
df_alltags <- tbl_alltags \%>\% 
  collect() \%>\% 
  as.data.frame() 

# Create site summaries for all sites within detection data with time in
# default hours using data.frame df_alltags
site_summary <- siteSum(tbl_alltags)

# Create site summaries for only select sites with time in minutes
sub <- filter(df_alltags, recvDeployName \%in\% 
                c("Niapiskau", "Netitishi", "Old Cur", "Washkaugou"))
site_summary <- siteSum(sub, units = "mins")

# Create site summaries for only a select species, Red Knot
site_summary <- siteSum(filter(df_alltags, speciesEN == "Red Knot"))
}
