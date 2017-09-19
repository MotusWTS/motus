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
                              "Accept"="application/json"),
                          timeout = 300,
                          verbose = FALSE)
                      )

    URL = file.path(Motus$dataServerURL, API)

    for (i in 1:2) {
        ## at most two iterations; the second allows for
        ## reauthentication when the authToken has expired

        if (auth) {
            ## Note: due its active binding if Motus$authToken is
            ## currently NULL, the following will generate a call to
            ## srvAuth, which in turn calls this srvQuery, but with
            ## auth=FALSE.  If authentication on that call fails,
            ## an error propagates up, exiting this function.

            query = list(authToken = Motus$authToken)

        } else {
            query = list()
        }
        query = c(query, params)

        json = query %>% jsonlite::toJSON (auto_unbox=TRUE, null="null")

        if(show)
            cat(json, "\n")

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
        if (! is.null(rv$error)) {
            if (rv$error %in% c("token expired", "token invalid")) {
                Motus$authToken = NULL
                next
            }
            stop(rv$error)
        }
        if (! is.null(rv$data))
            return(rv$data)
        return(rv)
    }
}
