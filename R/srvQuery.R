#' Send a query to the data server API
#'
#' @param API one of the Motus$API_DATA_... constants
#'
#' @param params named list of API-specific parameters
#'
#' @param requestType "post" or "get"; default: "post".
#'
#' @param show if TRUE, print the request to the console before submitting to motus
#'
#' @param JSON if TRUE, return results as JSON-format string; otherwise, as R list
#'
#' @param auth if TRUE, the default, the API requires an
#'     authentication token, which will be included automatically from \code{Motus$authToken}
#' Otherwise, an authentication token will be requested using the credentials in \code{Motus[c("userLogin", "userPassword")]}
#'
#' @return the result of sending the request to the data server API.  The
#'     result is a JSON-format character scalar if \code{json} is
#'     \code{TRUE}; otherwise it is an R list with named components,
#'     extracted from the JSON return value.
#'
#' @note If you have not already entered your motus login credentials
#'     in this R session, you will be prompted for them.
#'
#' @author John Brzustowski
#'     \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

srvQuery = function (API, params = NULL, requestType="post", show=FALSE, JSON=FALSE, auth=TRUE) {
    curl = RCurl::getCurlHandle()
    RCurl::curlSetOpt(.opts=list(verbose=0, header=0, failonerror=0), curl=curl)
    # params is a named list of parameters which will be passed along in the JSON query

    ## query object for getting project list

    if (auth)
        query = list(authToken = Motus$authToken)
    else
        query = list()
    query = c(query, params)

    json = query %>% jsonlite::toJSON (auto_unbox=TRUE, null="null")

    if(show)
        cat(json, "\n")

    URL = file.path(Motus$dataServerURL, API)

    tryCatch({
        if (requestType == "post")
            resp = RCurl::postForm(URL, json=json, style="post", curl=curl, .contentEncodeFun=RCurl::curlPercentEncode)
        else
            resp = RCurl::getForm(URL, json=json, curl=curl)
        resp = memDecompress(structure(resp, `Content-Type`=NULL), "gzip", asChar=TRUE)
        if (JSON)
            return (resp)
        if (grepl("^[ \r\n]*$", resp))
            return(list())
        rv = jsonlite::fromJSON(resp)
        if (! is.null(rv$data))
            return(rv$data)
        return(rv)
    }, error=function(e) {
        stop ("dataQuery error: ", as.character(e))
    })
}