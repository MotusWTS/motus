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
#' \item{API_RECEIVERS_FOR_PROJECT}{URL to call for getting a list of receiver deployments for a project}
#' \item{API_DEVICE_ID_FOR_RECEIVER}{URL to call for getting the device ID for a receiver}
#' \item{API_BATCHES_FOR_TAG_PROJECT}{URL to call for getting batches for a tag project}
#' \item{API_BATCHES_FOR_RECEIVER}{URL to call for getting batches for a receiver}
#' \item{API_BATCHES_FOR_RECEIVER_PROJECT}{URL to call for getting batches for a receiver project}
#' \item{API_GPS_FOR_TAG_PROJECT}{URL to call for getting GPS fixes for a tag project}
#' \item{API_GPS_FOR_RECEIVER_PROJECT}{URL to call for getting GPS fixes for a receiver project}
#' \item{API_METADATA_FOR_TAGS}{URL to call for getting metadata for tags}
#' \item{API_METADATA_FOR_RECEIVERS}{URL to call for getting metadata for receivers}
#' \item{API_TAGS_FOR_AMBIGIUITIES}{URL to call for getting motus tagIDs represented by an ambiguity ID}
#' \item{FLOAT_FIELDS}{list of API fieldnames requiring floating point values}
#' \item{FLOAT_REGEX}{regex to recognize fields requiring fixups in API queries}
#' }
#'
#' and variables are:
#'
#' \describe{
#' \item{userLogin}{login name for user at motus.org}
#' \item{userPassword}{password for user at motus.org}
#' \item{projects}{project IDs for user at motus.org}
#' \item{dataServerURL}{URL to data server}
#' \item{dbDir}{path to folder with project and tag databases}
#' }
#'
#' @seealso \link{\code{Motus}}
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

.onLoad = function(...) {
    ## interim location of unprotected local data server

    dataServerURL = "https://sgdata.motus.org/data"

    ## Assign constants

    with(Motus,
    {
        ## API entry points for the data server (these are relative to the data server URL)

        API_DATA_AUTHENTICATE = "custom/authenticate_user"

        ## API entry points for the motus server (absolute URLs)

        API_REGISTER_TAG = "https://motus.org/api/tag/register"
        API_DEPLOY_TAG   = "https://motus.org/api/tag/deploy"
        API_SEARCH_TAGS  = "https://motus.org/api/tags/search"

        ## API entry points for the data server (URLs relative to dataServerURL)
        API_DEVICE_ID_FOR_RECEIVER              = "custom/deviceID_for_receiver"
        API_RECEIVERS_FOR_PROJECT               = "custom/receivers_for_project"
        API_BATCHES_FOR_TAG_PROJECT             = "custom/batches_for_tag_project"
        API_BATCHES_FOR_RECEIVER                = "custom/batches_for_receiver"
        API_RUNS_FOR_TAG_PROJECT                = "custom/runs_for_tag_project"
        API_RUNS_FOR_RECEIVER                   = "custom/runs_for_receiver"
        API_HITS_FOR_TAG_PROJECT                = "custom/hits_for_tag_project"
        API_HITS_FOR_RECEIVER                   = "custom/hits_for_receiver"
        API_GPS_FOR_TAG_PROJECT                 = "custom/gps_for_tag_project"
        API_GPS_FOR_RECEIVER                    = "custom/gps_for_receiver"
        API_METADATA_FOR_TAGS                   = "custom/metadata_for_tags"
        API_METADATA_FOR_RECEIVERS              = "custom/metadata_for_receivers"
        API_TAGS_FOR_AMBIGUITIES                = "custom/tags_for_ambiguities"
        API_SIZE_OF_UPDATE_FOR_TAG_PROJECT      = "custom/size_of_update_for_tag_project"
        API_SIZE_OF_UPDATE_FOR_RECEIVER         = "custom/size_of_update_for_receiver"

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
    sessionVariable("authToken", srvAuth)
    sessionVariable("dataServerURL", "URL of data server", val=dataServerURL)  ## FIXME: switch to wrapper URL once implemented

    with(Motus,
    {
        projects = integer(0)   ## vector of projectIDs to which user has access
        dbDir = getwd()         ## folder where tag and receiver databases are stored
    })
}
