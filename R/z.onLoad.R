#' Initialize constants and writable storage for the motus package
#'
#' This function initializes the motus_vars environment that holds
#' constants (whose bindings are locked) and session variables (not
#' locked) used by this package.
#'
#' @details Constants are:
#'
#' \describe{
#' \item{API_API_INFO}{URL to call for getting information about the (data) API}
#' \item{API_REGISTER_TAG}{URL to call for registering a tag}
#' \item{API_DEPLOY_TAG}{URL to call for deploying a tag}
#' \item{API_SEARCH_TAGS}{URL to call for listing registered tags}
#' \item{API_RECEIVERS_FOR_PROJECT}{URL to call for getting a list of receiver deployments for a project}
#' \item{API_DEVICE_ID_FOR_RECEIVER}{URL to call for getting the device ID for a receiver}
#' \item{API_BATCHES_FOR_TAG_PROJECT}{URL to call for getting batches for a tag project}
#' \item{API_BATCHES_FOR_RECEIVER}{URL to call for getting batches for a receiver}
#' \item{API_BATCHES_FOR_ALL}{URL to call for getting batches for any receiver}
#' \item{API_GPS_FOR_TAG_PROJECT}{URL to call for getting GPS fixes for a tag project}
#' \item{API_GPS_FOR_RECEIVER}{URL to call for getting GPS fixes for a receiver project}
#' \item{API_PULSE_COUNTS_FOR_RECEIVER}{URL to call for getting antenna pulse counts for a receiver}
#' \item{API_METADATA_FOR_TAGS}{URL to call for getting metadata for tags}
#' \item{API_METADATA_FOR_RECEIVERS}{URL to call for getting metadata for receivers}
#' \item{API_RECV_METADATA_FOR_PROJECTS}{URL to call for getting receiver metadata by projects}
#' \item{API_TAG_METADATA_FOR_PROJECTS}{URL to call for getting tag metadata by projects}
#' \item{API_TAGS_FOR_AMBIGIUITIES}{URL to call for getting motus tagIDs represented by an ambiguity ID}
#' \item{API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT}{URL to call for getting list of ambiguous project IDs for a project}
#' \item{API_ACTIVITY_FOR_ALL}{URL to call for getting activity for all projects/receivers}
#' \item{API_GPS_FOR_RECIEVER_ALL}{URL to call for getting GPS fixes for all receivers}
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
#' @seealso \code{\link{motus_vars}}
#'
#' @noRd

.onLoad = function(...) {
    
    options(motus.test.max = 15)
    
    # default location of motus data server, unless user has already assigned
    # a value to "motusServerURL" in the global environment
    if(!exists("motusServerURL")) motusServerURL <- "https://sandbox.motus.org/api"
    dataServerURL <- file.path(motusServerURL, "sgdata")

    ## Assign constants

    with(motus_vars,
    {
        ## API entry points for the data server (these are relative to the data server URL)

        API_DATA_AUTHENTICATE = "custom/authenticate_user"

        ## API entry points for the motus server (absolute URLs)

        #API_REGISTER_TAG = file.path(motusServerURL, "tag/register")
        #API_DEPLOY_TAG   = file.path(motusServerURL, "tag/deploy")
        #API_SEARCH_TAGS  = file.path(motusServerURL, "tags/search")

        ## API entry points for the data server (URLs relative to dataServerURL)
        API_API_INFO                            = "custom/api_info"
        API_ACTIVITY_FOR_BATCHES                = "custom/activity_for_batch"
        API_DEVICE_ID_FOR_RECEIVER              = "custom/deviceID_for_receiver"
        API_RECEIVERS_FOR_PROJECT               = "custom/receivers_for_project"
        API_BATCHES_FOR_TAG_PROJECT             = "custom/batches_for_tag_project"
        API_BATCHES_FOR_RECEIVER                = "custom/batches_for_receiver"
        API_BATCHES_FOR_ALL                     = "custom/batches_for_all"
        API_RUNS_FOR_TAG_PROJECT                = "custom/runs_for_tag_project"
        API_RUNS_FOR_RECEIVER                   = "custom/runs_for_receiver"
        API_HITS_FOR_TAG_PROJECT                = "custom/hits_for_tag_project"
        API_HITS_FOR_RECEIVER                   = "custom/hits_for_receiver"
        API_GPS_FOR_TAG_PROJECT                 = "custom/gps_for_tag_project"
        API_GPS_FOR_RECEIVER                    = "custom/gps_for_receiver"
        API_PULSE_COUNTS_FOR_RECEIVER           = "custom/pulse_counts_for_receiver"
        API_METADATA_FOR_TAGS                   = "custom/metadata_for_tags"
        API_METADATA_FOR_RECEIVERS              = "custom/metadata_for_receivers"
        API_NODES_FOR_TAG_PROJECT               = "custom/nodes_for_tag_project"
        API_NODES_FOR_RECEIVER                  = "custom/nodes_for_receiver"
        API_RECV_METADATA_FOR_PROJECTS          = "custom/recv_metadata_for_projects"
        API_TAG_METADATA_FOR_PROJECTS           = "custom/tag_metadata_for_projects"
        API_TAGS_FOR_AMBIGUITIES                = "custom/tags_for_ambiguities"
        API_SIZE_OF_UPDATE_FOR_TAG_PROJECT      = "custom/size_of_update_for_tag_project"
        API_SIZE_OF_UPDATE_FOR_RECEIVER         = "custom/size_of_update_for_receiver"
        API_PROJECT_AMBIGUITIES_FOR_TAG_PROJECT = "custom/project_ambiguities_for_tag_project"
        API_ACTIVITY_FOR_ALL                    = "custom/activity_for_all"
        API_GPS_FOR_RECIEVER_ALL                = "custom/gps_for_receiver_all"

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

    for (n in ls(motus_vars))
        lockBinding(n, motus_vars)

    ## Assign non-constant variables which are not session variables


    ## Assign active bindings for variables for which we ask for values only
    ## the first time they are needed.

    sessionVariable("userLogin", "login name at motus.org")
    sessionVariable("userPassword", "password at motus.org")

    ## Add additional variables
    sessionVariable("authToken", srvAuth)
    sessionVariable("dataServerURL", "URL of data server", val=dataServerURL)  ## FIXME: switch to wrapper URL once implemented

    with(motus_vars,
    {
        dataVersion = 0L  ## Current dataVersion returned by server
        projects = 0L     ## vector of projectIDs to which user has access
        receivers = 0L
        dbDir = getwd()   ## folder where tag and receiver databases are stored
    })
    
    # CRAN Note avoidance
    if(getRversion() >= "2.15.1")
        utils::globalVariables(
            # Vars used in Non-Standard Evaluations, declare here to
            # avoid CRAN warnings
            c(".") # piping requires '.' at times
        )
}
