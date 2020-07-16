#' determine the model from a lotek serial number
#'
#' The serial number determines the receiver model in most cases, but
#' for a few receivers, additional fields from the .DTA file are needed.
#'
#' @param serno character scalar; receiver serial number, e.g. "Lotek-123"
#' @param extra a named character vector of additional .DTA file fields
#'   Currently, this parameter is ignored.
#'
#' @return a character scalar with the receiver model
#'
#' @noRd

getLotekModel = function(serno, extra) {

    ## get bare serial number by dropping "Lotek-" (first 6 chars)
    bareno = substring(serno, 7)

    ## map to model as per info from Lotek:

    ## > Yes, serial number uniquely identifies receiver.  All the SRX600
    ## > receiver serial numbers are 6###.  The SRX800 serial numbers start at 1.
    ## > It will be a long time before we get to 6000.  The old SRX400A models
    ## > were 9###A and up.
    ## ---
    ## > SRX-DL receivers have serial numbers 8###.

    ## and further:

    ## > As of June 1 2016 we decided to switch the SRX800 D
    ## > variant SN allocation to the format, D######,
    ## > i.e. D000426. This helps us distinguish a D variant
    ## > from a M / MD variant. The change in SN allocation
    ## > actually occurs from SN 000390 to SN D000391.

    if (substr(bareno, 1, 1) == "D") {
        model = "SRX800D"
    } else if (bareno >= "9000A") {
        model = "SRX400A"
    } else if (bareno >= "8000") {
        model = "SRX-DL"
    } else if (bareno >= "6000") {
        model = "SRX600"
    } else if (as.integer(bareno) >= 391) {
        ## per Lotek, it's not a model "D"
        model = "SRX800M/MD"
    } else {
        model = "SRX800"
    }
    return(model)
}
