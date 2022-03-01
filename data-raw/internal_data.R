source("data-raw/field_names.R")
source("data-raw/updatesql.R")


usethis::use_data(sql_tables, sql_fields, sql_versions, internal = TRUE, overwrite = TRUE)

