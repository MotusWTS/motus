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
    RCurl::curlSetOpt(curl=curl,
                      .opts = list(
                          httpheader = c(
                              "Content-Type"="application/json",
                              "Accept"="application/json"),
                          timeout = 300,
                          verbose = FALSE)
                      )
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

    tokenReset = FALSE
    repeat {
        tryCatch({
            if (requestType == "post")
                resp = RCurl::postForm(URL, json=json, style="post", curl=curl, .contentEncodeFun=RCurl::curlPercentEncode)
            else
                resp = RCurl::getForm(URL, json=json, curl=curl)
            resp = memDecompress(structure(resp, `Content-Type`=NULL), "bzip2", asChar=TRUE)
            if (JSON)
                return (resp)
            if (grepl("^[ \r\n]*$", resp))
                return(list())
            rv = jsonlite::fromJSON(resp)
            if ("error" %in% names(rv))
                stop(rv$error)
            if (! is.null(rv$data))
                return(rv$data)
            return(rv)
        }, error=function(e) {
            e = as.character(e)
            if (any(grepl("authorization with motus failed", e))) {
                if (tokenReset) {
                    e = "Motus authorization failed.\nPlease retry the function (you will be prompted again for a username and password).\n"
                    Motus$authToken <- NULL
                    Motus$userLogin <- NULL
                    Motus$userPassword <- NULL
                } else {
                    ## we haven't tried resetting the authToken, so do that now and quietly retry the query
                    ## this isn't sufficient as a mechanism for mediating between multiple user R sessions accessing
                    ## the server, because it's a race condition (will the other session re-authorize before this session
                    ## submits the real query?).  But at least it deals with token expiry.
                    Motus$authToken <- NULL
                    tokenReset <<- TRUE
                    query$authToken <<- Motus$authToken ## active binding which triggers a call to srvAuth
                    return()  ## just returning from the error handler
                }
            }
            ## propagate the error
            stop ("A query to the motus data server failed: ", e)
        })
        if (! tokenReset)
            stop ("Weird error in srvQuery: please report to motus.org") ## this loop should happen at most twice, and twice only if a tokenReset occurred
    }
}
