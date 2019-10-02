if(requireNamespace('spelling', quietly = TRUE)) {
  if(!identical(Sys.getenv("APPVEYOR"), "True")) {
    spelling::spell_check_test(vignettes = TRUE, error = FALSE,
                               skip_on_cran = TRUE)
  }
}
