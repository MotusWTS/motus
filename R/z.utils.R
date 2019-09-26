make_master <- function() {
  l <- readLines("./R/z.onLoad.R") %>%
    stringr::str_replace(
      "(https://sandbox.motus.org/api)|(https://beta.motus.org/api)", 
      "https://motus.org/api")
  writeLines(l, "./R/z.onLoad.R")
}

make_beta <- function() {
  l <- readLines("./R/z.onLoad.R") %>%
    stringr::str_replace(
      "(https://sandbox.motus.org/api)|(https://motus.org/api)", 
      "https://beta.motus.org/api")
  writeLines(l, "./R/z.onLoad.R")
}

make_sandbox <- function() {
  l <- readLines("./R/z.onLoad.R") %>%
    stringr::str_replace(
      "(https://beta.motus.org/api)|(https://motus.org/api)", 
      "https://sandbox.motus.org/api")
  writeLines(l, "./R/z.onLoad.R")
}

ensure_version <- function(v) {
 l <- readLines("./DESCRIPTION")
 if(any(stringr::str_detect(l, paste0("Version: ", v)))) {
   message("Version is ", v)
 } else {
   message("Check DESCRIPTION, version is not ", v) 
 }
}