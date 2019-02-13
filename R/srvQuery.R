#' Send a query to the data server API
#'
#' @param API one of the Motus$API_DATA_... constants
#' @param params named list of API-specific parameters
#' @param show if TRUE, print the request to the console before submitting to
#'   motus
#' @param JSON if TRUE, return results as JSON-format string; otherwise, as R
#'   list
#' @param auth if TRUE, the default, the API requires an authentication token,
#'   which will be included automatically from \code{Motus$authToken} Otherwise,
#'   an authentication token will be requested using the credentials in
#'   \code{Motus[c("userLogin", "userPassword")]}
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
#'     
#' @keywords internal

srvQuery <- function (API, params = NULL, show = FALSE, JSON = FALSE, auth = TRUE) {
    
    url <- file.path(Motus$dataServerURL, API)
    ua <- httr::user_agent(agent = "http://github.com/MotusWTS/motus")
    
    # Set curl options
    httr::set_config(httr::accept_json())
    httr::set_config(httr::timeout(300))
    #httr::set_config(httr::verbose())
    
    for (i in 1:2) {
        ## at most two iterations; the second allows for
        ## reauthentication when the authToken has expired
        
        if (auth) {
            ## Note: due its active binding if Motus$authToken is
            ## currently NULL, the following will generate a call to
            ## srvAuth, which in turn calls this srvQuery, but with
            ## auth=FALSE.  If authentication on that call fails,
            ## an error propagates up, exiting this function.
            
            query <- list(authToken = Motus$authToken)
            
        } else {
            query <- list()
        }
        query <- c(query, params)
        
        json <- jsonlite::toJSON(query, auto_unbox = TRUE, null = "null")
        
        if(show) message(json, "\n")
        
        resp <- httr::POST(url, body = list("json" = json), encode = "form",
                           httr::config(http_content_decoding = 0)) %>%
            httr::content(as = "raw") %>%
            memDecompress("bzip2", asChar = TRUE)
        
        Encoding(resp) <- "UTF-8"
        
        if (JSON) return(resp)
        if (grepl("^[ \r\n]*$", resp)) return(list())
        
        rv <- jsonlite::fromJSON(resp)
        
        if (! is.null(rv$error)) {
            if (rv$error %in% c("token expired", "token invalid")) {
                Motus$authToken = NULL
                next
            }
            stop(rv$error)
        }
        if (! is.null(rv$data)) {
            return(rv$data)
        }
        return(rv)
    }
}
