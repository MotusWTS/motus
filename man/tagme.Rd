% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tagme.R
\name{tagme}
\alias{tagme}
\title{Download motus tag detections to a database}
\usage{
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
}
\arguments{
\item{projRecv}{Numeric. Project code from motus.org, \emph{or} character receiver
serial number.}

\item{update}{Logical. Download and merge new data (Default \code{TRUE})?}

\item{new}{Logical. Create a new database (Default \code{FALSE})? Specify
\code{new = TRUE} to create a new local copy of the database to be downloaded.
Otherwise, it assumes the database already exists, and will stop with an
error if it cannot find it in the current directory. This is mainly to
prevent inadvertent downloads of large amounts of data that you already
have!}

\item{dir}{Character. Path to the folder where you are storing databases
IF \code{NULL} (default), uses current working directory.}

\item{countOnly}{Logical. If \code{TRUE}, return only a count of items that would
need to be downloaded in order to update the database (Default \code{FALSE}).}

\item{forceMeta}{Logical. If \code{TRUE}, re-download metadata for tags and
receivers, even if we already have them.}

\item{rename}{Logical. If current SQLite database is of an older data
version, automatically rename that database for backup purposes and
download the newest version. If \code{FALSE} (default), user is prompted for
action.}

\item{skipActivity}{Logical. Skip checking for and downloading \code{activity}?
See \code{?activity} for more details}

\item{skipNodes}{Logical. Skip checking for and downloading \code{nodeData}? See
\code{?nodeData} for more details}

\item{skipDeprecated}{Logical. Skip fetching list of deprecated batches
stored in \code{deprecated}. See \code{?deprecateBatches()} for more details.}
}
\value{
a SQLite Connection for the (possibly updated) database, or a data
frame of counts if \code{countOnly = TRUE}.
}
\description{
This is the main motus function for accessing and updating your data. This
function downloads motus data to a local SQLite data base in the name of
\code{project-XXX.motus} or \code{RECIVER_NAME.motus}. If you are having trouble with
a particular data base timing out on downloads, see \code{srvTimeout()} for
options.
}
\examples{

\dontrun{

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
}

}
\seealso{
\code{tellme()}, which is a synonym for
\code{tagme(..., countOnly = TRUE)}
}
