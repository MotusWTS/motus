#' Constants and writable storage for the motus package
#'
#' This is an environment that holds constants (whose bindings are locked)
#' and session variables (not locked) used by this package.
#'
#' @details Constants are:
#'
#' - API_REGISTER_TAG - URL to call for registering a tag
#' - API_DEPLOY_TAG - URL to call for deploying a tag
#' - API_SEARCH_TAGS - URL to call for listing registered tags
#' - API_BATCHES_FOR_TAG_PROJECT - URL to call for getting batches for a tag project
#' - API_BATCHES_FOR_RECEIVER_PROJECT - URL to call for getting batches for a receiver project
#' - API_RUNS_FOR_TAG_PROJECT - URL to call for getting runs from a tag project in a batch
#' - FLOAT_FIELDS - list of API fieldnames requiring floating point values
#' - FLOAT_REGEX - regex to recognize fields requiring fixups in API queries
#'
#' and session variables are:
#'
#' - userLogin - login name for user at motus.org
#' - userPassword - password for user at motus.org
#' - myProjects - project IDs for user at motus.org
#'
#' @noRd

motus_vars <- new.env(emptyenv())
