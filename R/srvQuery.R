#' Send a query to the data server API
#'
#' @param API one of the motus_vars$API_DATA_... constants
#' @param params named list of API-specific parameters
#' @param show if TRUE, print the request to the console before submitting to
#'   motus
#' @param JSON if TRUE, return results as JSON-format string; otherwise, as R
#'   list
#' @param auth if TRUE, the default, the API requires an authentication token,
#'   which will be included automatically from \code{motus_vars$authToken}
#'   Otherwise, an authentication token will be requested using the credentials
#'   in \code{motus_vars[c("userLogin", "userPassword")]}
#' @param url Character. API url, defaults to `motus_vars$dataServerURL`
#'
#' @return the result of sending the request to the data server API.  The
#'     result is a JSON-format character scalar if \code{json} is
#'     \code{TRUE}; otherwise it is an R list with named components,
#'     extracted from the JSON return value.
#'
#' @note If you have not already entered your motus login credentials
#'     in this R session, you will be prompted for them.
#'     
#' @noRd

srvQuery <- function (API, params = NULL, show = FALSE, JSON = FALSE, 
                      auth = TRUE, url = motus_vars$dataServerURL,
                      timeout = 120, verbose = FALSE) {
  
    url <- file.path(url, API)
    ua <- httr::user_agent(agent = "http://github.com/MotusWTS/motus")
    
    # Set curl options
    httr::set_config(httr::accept_json())
    httr::set_config(httr::content_type_json())
    if(verbose) httr::set_config(httr::verbose()) # Set as needed for debugging
    
    for (i in 1:2) {
        ## at most two iterations; the second allows for
        ## reauthentication when the authToken has expired
        
        if (auth) {
            ## Note: due its active binding if motus_vars$authToken is
            ## currently NULL, the following will generate a call to
            ## srvAuth, which in turn calls this srvQuery, but with
            ## auth=FALSE.  If authentication on that call fails,
            ## an error propagates up, exiting this function.
            
            query <- list(authToken = motus_vars$authToken, 
                          dataVersion = motus_vars$dataVersion)
            
        } else {
            query <- list()
        }
        
        query <- c(query, params)

        json <- jsonlite::toJSON(query, auto_unbox = TRUE, null = "null")
        
        if(show) message(json, "\n")
        
        if(verbose) message(url, "\n", json)
        
        api_query <- function(url, json, ua, timeout) {
          httr::POST(url, body = list("json" = json), encode = "form",
                     httr::config(http_content_decoding = 0), ua, 
                     httr::timeout(timeout))
        }
        resp <- try(api_query(url, json, ua, timeout), silent = TRUE)
        
        if(class(resp) == "try-error") {
          if(stringr::str_detect(resp, "aborted by an application callback")){
            stop(resp, call. = FALSE)
          } else if (stringr::str_detect(resp, "Timeout was reached")) {
            message("The server did not respond within ", timeout, 
                    "s. Trying again...")
            resp <- try(api_query(url, json, ua, timeout), silent = TRUE)
            if(class(resp) == "try-error" && 
               stringr::str_detect(resp, "Timeout was reached")) {
              stop("The server is not responding, please try again later.", 
                   call. = FALSE)
            } else if(class(resp) == "try-error") {
              stop(resp, call. = FALSE)
            }
          } else {
            resp <- api_query(url, json, ua, timeout)
          }
        }
        
        # Catch http errors
        if(httr::http_error(resp)) {
          if(httr::http_type(resp) == "application/json") {
            p <- jsonlite::fromJSON(httr::content(resp, "text"), simplifyVector = FALSE)
          } else if (httr::status_code(resp) == 500) {
            p <- list(errorMsg = "Internal Server Error")
          } else p <- list(errorMsg = "Unknown Error")
          
          stop(sprintf("Motus API request failed [%s]\n%s",
                       httr::status_code(resp),
                       p$errorMsg), 
               call. = FALSE)
        }
        
        resp <- resp %>%
          httr::content(as = "raw") %>%
          memDecompress("bzip2", asChar = TRUE)
        
        Encoding(resp) = "UTF-8"
        
          
        if (JSON) return(resp)
        if (grepl("^[ \r\n]*$", resp)) return(list())
        
        rv <- jsonlite::fromJSON(resp)
        
        # Catch call errors
        if (! is.null(rv$error)) {
            if (rv$error %in% c("token expired", "token invalid")) {
                motus_vars$authToken = NULL
                next
            }
          er <- stringr::str_replace_all(rv$error, "\\&\\#47\\;", "/")
          stop("Server returned error '", er, "'", call. = FALSE)
        }
        
        if ("data" %in% names(rv)) {
            return(rv$data)
        }
        return(rv)
    }
}
