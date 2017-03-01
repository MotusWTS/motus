#' Send a query to the motus API
#'
#' @param API one of the Motus$API_... constants
#'
#' @param params named list of API-specific parameters
#'
#' @param requestType "post" or "get"; default: "post".
#'
#' @param show if TRUE, print the request to the console before submitting to motus
#'
#' @param JSON if TRUE, return results as JSON-format string; otherwise, as R list
#'
#' @return the result of sending the request to the motus API.  The
#'     result is a JSON-format character scalar if \code{json} is
#'     \code{TRUE}; otherwise it is an R list with named components,
#'     extracted from the JSON return value.
#'
#' @note If you have not already entered your motus login credentials
#'     in this R session, e.g. by calling \code{\link{motusLogin()}},
#'     this function will prompt you for them.
#'
#' @author John Brzustowski
#'     \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

motusQuery = function (API, params = NULL, requestType="post", show=FALSE, JSON=FALSE) {
    curl = RCurl::getCurlHandle()
    RCurl::curlSetOpt(.opts=list(verbose=0, header=0, failonerror=0), curl=curl)
    # params is a named list of parameters which will be passed along in the JSON query

    date = Sys.time() %>% format("%Y%m%d%H%M%S")

    ## query object for getting project list

    query = c(
        list(
            date = date,
            format = "jsonp",
            login = Motus$userLogin,
            pword = Motus$userPassword
            ),
        params)

    json = query %>% jsonlite::toJSON (auto_unbox=TRUE, null="null")

    ## add ".0" to the end of any integer-valued floating point fields
    ## whose names are known to require floats
    json = gsub(Motus$FLOAT_REGEX, "\\1.0\\3", json, perl=TRUE)

    if(show)
        cat(json, "\n")

    tryCatch({
        if (requestType == "post")
            resp = RCurl::postForm(API, json=json, style="post", curl=curl)
        else
            resp = RCurl::getForm(API, json=json, curl=curl)
        if (JSON)
            return (resp)
        if (grepl("^[ \r\n]*$", resp))
            return(list())
        rv = jsonlite::fromJSON(resp)
        if (! is.null(rv$data))
            return(rv$data)
        return(rv)
    }, error=function(e) {
        stop ("motusQuery error: ", as.character(e))
    })
}
