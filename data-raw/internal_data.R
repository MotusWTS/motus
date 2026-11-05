source("data-raw/field_names.R")
source("data-raw/updatesql.R")

t <- DBI::dbConnect(RSQLite::SQLite(), system.file("extdata", "project-176.motus", package = "motus"))

db_vars <- tibble(table = DBI::dbListTables(t)) %>%
  mutate(name_table = map(table, ~DBI::dbListFields(t, .))) %>%
  unnest(name_table)

usethis::use_data(sql_tables, sql_fields, sql_versions, db_vars, internal = TRUE, overwrite = TRUE)

