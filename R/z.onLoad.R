#' Initialize constants and writable storage for the motus package
#'
#' This function initializes the Motus environment that holds
#' constants (whose bindings are locked) and session variables (not
#' locked) used by this package.
#'
#' @details Constants are:
#'
#' \describe{
#' \item{API_REGISTER_TAG}{URL to call for registering a tag}
#' \item{API_DEPLOY_TAG}{URL to call for deploying a tag}
#' \item{API_SEARCH_TAGS}{URL to call for listing registered tags}
#' \item{FLOAT_FIELDS}{list of API fieldnames requiring floating point values}
#' \item{FLOAT_REGEX}{regex to recognize fields requiring fixups in API queries}
#' }
#'
#' and variables are:
#'
#' \describe{
#' \item{userLogin}{login name for user at motus.org}
#' \item{userPassword}{password for user at motus.org}
#' \item{myProjects}{project IDs for user at motus.org}
#' }
#'
#' @seealso \link{\code{Motus}}
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

.onLoad = function(...) {
    ## Assign constants

    with(Motus,
    {
        ## API entry points

        API_REGISTER_TAG = "https://motus.org/api/tag/register"
        API_DEPLOY_TAG   = "https://motus.org/api/tag/deploy"
        API_SEARCH_TAGS  = "https://sandbox.motus.org/api/tags/search"

        ## a list of field names which must be formatted as floats so that the
        ## motus API recognizes them correctly.  This means that if they happen
        ## to have integer values, a ".0" must be appended to the JSON field
        ## value.  We do this before sending any query.  This is only required
        ## due to motus upstream using a weirdly picky JSON parser.

        FLOAT_FIELDS = c("tsStart", "tsEnd", "regStart", "regEnd",
                         "offsetFreq", "period", "periodSD", "pulseLen",
                         "param1", "param2", "param3", "param4", "param5", "param6",
                         "ts", "nomFreq", "deferTime", "lat", "lon", "elev")

        ## a regular expression for replacing values that need to be floats
        ## Note: only works for named scalar parameters; i.e. "XXXXX":00000,
        ## and not for e.g. named arrays.

        FLOAT_REGEX = sprintf("((%s):-?[0-9]+)([,}])",
                              paste(sprintf("\"%s\"", FLOAT_FIELDS), collapse="|"))

        ## the earliest valid date from a sensorgnome (= as.numeric(ymd("2010-01-01")))
        SG_EPOCH = 1262304000
    })

    ## bind all constants

    for (n in ls(Motus))
        lockBinding(n, Motus)

    ## Assign active bindings for variables for which we ask for values only
    ## the first time they are needed.

    sessionVariable("userLogin", "login name at motus.org")
    sessionVariable("userPassword", "password at motus.org")

    ## Add additional variables

    with(Motus,
    {
        myProjects = integer(0)  ## vector of projectIDs to which user has access
    })
}
