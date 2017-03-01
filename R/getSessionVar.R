#' if a session variable does not yet have a value, prompt
#' the user to enter it.
#'
#' Session variables are typically only set once per R session.
#' They include items such as user login and password for motus.org
#'
#'
#' @details
#' The job folder must contain a file called tagreg.txt with these lines:
#'
#' \itemize{
#' \item  motusProjID:  XXX (numeric project ID)
#' \item  tagModel: NTQB-??? (as given on the Lotek invoice)
#' \item  nomFreq: 166.38 (nominal tag frequency, in MHz)
#' \item  species: XXXXX (optional 4-letter code or motus numeric species ID)
#' \item  deployDate: YYYY-MM-DD (earliest likely deployment date for any tags)
#' \item  codeSet: X (optional codeset ; default: 4 for "Lotek4"; can also be 3 for "Lotek3")
#' }
#'
#' as well as one or more recording files with names like \code{tagXXX.wav}
#' where \code{XXX} is the manufacturer's tag ID, typically 1 to 3 digits.
#' When there are recordings of tags with the same ID but different burst intervals,
#' the 2nd, 3rd, and so on such tags are given names like \code{tagXXX.1.wav, tagXXX.2.wav, ...}
#'
#' @note By default, we assume each tag was recorded at 4 kHz below
#'     its nominal frequency; e.g.  at 166.376 MHz for a nominal
#'     166.38 MHz tag.  If that's not true, the filename should
#'     include a portion of the form \code{@XXX.XXX} giving the
#'     frequency at which it was recorded;
#'     e.g. \code{tag134@166.372.wav} indicates a tag recorded at
#'     166.372 MHz, rather than the default.
#'
#' Called by \code{\link{processServer}}.
#'
#' @param j the job
#'
#' @return  TRUE;
#'
#' @seealso \code{\link{processServer}}, which calls this function.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}
