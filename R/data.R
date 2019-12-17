#' Example shorebirds tags download from Motus
#'
#' An example data frame of shorebirds data (project 176)
#' 
#' Create with the following code:
#' 
#' ```
#' tags <- tagme(projRecv = 176, new = TRUE, update = TRUE)
#' shorebirds <- dplyr::tbl(tags, "alltagsGPS") %>%
#'   dplyr::collect()
#' ```
#'
#' @format A data frame with 108826 rows and 62 variables:
"shorebirds"