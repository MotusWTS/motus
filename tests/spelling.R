if(requireNamespace('spelling', quietly = TRUE) &&
   requireNamespace('hunspell', quietly = TRUE)) {
  dictionary("en_CA")
  spelling::spell_check_test(vignettes = TRUE, error = FALSE,
                             skip_on_cran = TRUE)
}
