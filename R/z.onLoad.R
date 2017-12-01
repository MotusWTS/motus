#' Make sure the motusClient package is installed, and load it.
#'
#' @export
#'
#' @author John Brzustowski \email{jbrzusto@@REMOVE_THIS_PART_fastmail.fm}

.onLoad = function(...) {

    ## make sure the motusClient package is installed and loaded

    ## Note: eventually, when the CRAN version of devtools supports
    ## loading dependent packages from github via the "Remotes:" field,
    ## this section can be replaced with a simple `require(motusClient)`

    if(!suppressWarnings(suppressMessages(require("motusClient",
                                                  quietly=TRUE, character.only=TRUE)))) {
        devtools::install_github("motusWTS/motusClient")
        suppressMessages(require("motusClient", character.only=TRUE))
    }
    addHook("ensureDBTables", updateMotusDb)
}
