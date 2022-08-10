library(glue)
library(dplyr)
library(stringr)


# ** GET FIELDS -----------------------------------------------------------


local_auth()
field_names <- srvSchema() %>%
  rename_all(tolower) %>%
  rename(column = column_name, table = table_name, type = data_type) %>%
  mutate(type = toupper(type),
         table = tolower(table)) %>%
  filter(!column %in% c("accessLevel"),
         !str_detect(column, "is_private"))


t <- data.frame()

# activity ------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "batches_activity")) %>%
  mutate(table = "activity",
         keys = column %in% c("batchID", "ant", "hourBin")) %>%
  bind_rows(t, .)

# activityAll ------------------------------------------------------------------
t <- filter(t, table == "activity") %>%
  mutate(table = "activityAll") %>%
  bind_rows(t, .)


# antDeps ------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "antdeps"),
         !column %in% c("projectID", "deviceID")) %>%
  mutate(table = "antDeps",
         keys = column %in% c("deployID", "port"),
         extra = list(
           c("CREATE INDEX IF NOT EXISTS antDeps_deployID on antDeps(deployID)",
             "CREATE INDEX IF NOT EXISTS antDeps_port on antDeps(port)"))) %>%
  bind_rows(t, .)

# batches ------------------------------------------------------------------
# "batches" table applies to batches_for_receiver and batches_for_tag
t <- field_names %>%
  filter(str_detect(table, "batches_for_tag_project$"),
         !column %in% c("version")) %>%
  mutate(table = "batches",
         keys = column == "batchID") %>%
  bind_rows(t, .)

# deprecated ------------------------------------------------------------------
# "deprecated" table applies to batches_for_receiver_deprecated and 
# batches_for_tag_deprecated

t <- field_names %>%
  filter(str_detect(table, "batches_for_tag_project_deprecated"),
         !column %in% c("motusProjectID", "motusDeviceID", "version")) %>%
  add_row(column = "removed", type = "INTEGER") %>%
  mutate(table = "deprecated",
         keys = column == "batchID") %>%
  bind_rows(t, .)


# gps --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "gps_for_tag"),
         !column %in% c("motusProjectID", "recvProjectID")) %>%
  mutate(table = "gps",
         keys = column == "gpsID",
         references = if_else(column == "batchID", "batches", ""),
         # Remove empty gps detections
         extra = list(
           c("DELETE FROM gps where lat = 0 and lon = 0 and alt = 0"))) %>%
  bind_rows(t, .)

# gpsAll --------------------------------------------------------------------
t <- filter(t, table == "gps") %>%
  mutate(table = "gpsAll",
         extra = purrr::map(extra, ~str_replace(., "gps", "gpsAll"))) %>%
  bind_rows(t, .)


# hits --------------------------------------------------------------------
# "hits" table applies to hits_for_receiver and hits_for_tag_project
t <- field_names %>%
  filter(str_detect(table, "hits_for_tag"),
         !column %in% c("projectID")) %>%
  mutate(
    table = "hits",
    keys = column == "hitID",
    not_nulls = column %in% c("runID", "batchID", "ts", "sig"),
    references = case_when(column == "runID" ~ "runs",
                           column == "batchID" ~ "batches"),
    extra = list(
      c("CREATE INDEX IF NOT EXISTS hits_batchID_ts on hits(batchID, ts)"))) %>%
  bind_rows(t, .)


# nodeData --------------------------------------------------------------------
# "nodeData" table applies to node_data_for_receiver & node_data_for_tag_project
t <- field_names %>%
  filter(str_detect(table, "node_data_for_tag"),
         !column %in% c("projectID", "deviceID")) %>%
  mutate(table = "nodeData",
         keys = column == "nodeDataID",
         not_nulls = column %in% 
           c("nodeDataID", "batchID", "ts", "nodeNum", "ant")) %>%
  bind_rows(t, .)

# nodeDeps --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "nodedeps"),
         !column %in% c("projectID", "deviceID", "nodeNum")) %>%
  mutate(table = "nodeDeps",
         keys = column == "nodeDeployID",
         not_nulls = column %in% c("deployID", "nodeDeployID", "tsStart")) %>%
  bind_rows(t, .)

# pulseCounts -----------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "pulse")) %>%
  mutate(table = "pulseCounts",
         keys = column %in% c("batchID", "ant", "hourBin"),
         not_nulls = column %in% c("batchID", "ant")) %>%
  bind_rows(t, .)

# recvDeps --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "recvdeps")) %>%
  add_row(column = "macAddress", type = "TEXT") %>%
  mutate(
    table = "recvDeps",
    keys = column == "deployID",
    extra = list(c(
      "CREATE INDEX IF NOT EXISTS recvDeps_serno on recvDeps(serno)",
      "CREATE INDEX IF NOT EXISTS recvDeps_deviceID on recvDeps(deviceID)",
      "CREATE INDEX IF NOT EXISTS recvDeps_projectID on recvDeps(projectID)"
      ))) %>%
  bind_rows(t, .)

# runs --------------------------------------------------------------------
# "runs" table applies to runs_for_receiver and runs_for_tag_project
t <- field_names %>%
  filter(str_detect(table, "runs_for_tag"),
         !column %in% c("projectID", "batchID")) %>%
  mutate(table = "runs",
         keys = column == "runID",
         not_nulls = column %in% c("batchIDbegin", "done", "motusTagID", "ant"),
         defaults = if_else(column == "done", 0, as.numeric(NA))) %>%
  bind_rows(t, .)

# species --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "tags_species")) %>%
  add_row(column = "sort", type = "INT") %>%
  mutate(table = "species",
         keys = column == "id",
         not_nulls = column %in% c("id")) %>%
  bind_rows(t, .)

# tagAmbig --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "tags_for_ambiguities"),
         !column %in% c("projectID", "batchID")) %>%
  add_row(column = "masterAmbigID", type = "INT") %>%
  mutate(table = "tagAmbig",
         keys = column == "ambigID",
         not_nulls = column == "ambigID") %>%
  bind_rows(t, .)

# tagDeps --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "tags_deps")) %>%
  add_row(column = "bandNumber", type = "TEXT") %>%
  add_row(column = "id", type = "INTEGER") %>%
  add_row(column = "bi", type = "INTEGER") %>%
  add_row(column = "fullID", type = "INTEGER") %>%
  add_row(column = "status", type = "TEXT") %>%
  mutate(table = "tagDeps",
         keys = column == "deployID",
         extra = list(c(
           "CREATE INDEX IF NOT EXISTS tagDeps_projectID on tagDeps(projectID)",
           "CREATE INDEX IF NOT EXISTS tagDeps_deployID on tagDeps(deployID)"
           ))) %>%
  bind_rows(t, .)

# tagProps --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "properties"),
         !column %in% c("projectID")) %>%
  mutate(
    table = "tagProps",
    keys = column == "propID",
    not_nulls = column %in% c("tagID", "deployID", "propName"),
    extra = list(c(
      "CREATE INDEX IF NOT EXISTS tagProps_deployID ON tagProps (deployID ASC)"
      ))) %>%
  bind_rows(t, .)


# tags --------------------------------------------------------------------
t <- field_names %>%
  filter(str_detect(table, "metadata_for_tags$")) %>%
  mutate(table = "tags",
         keys = column == "tagID",
         extra = list(c(
           "CREATE INDEX IF NOT EXISTS tags_projectID on tags(projectID)"))) %>%
  bind_rows(t, .)


# ** NOT FROM SCHEME ---------------------------------------------------------

# admInfo --------------------------------------------------------------------
t <- tribble(~column,        ~type,
                   "db_version",   "TEXT",
                   "data_version", "TEXT") %>%
  mutate(table = "admInfo") %>%
  bind_rows(t, .)

# batchRuns --------------------------------------------------------------------
t <- tribble(~column,   ~type,
                     "batchID", "INTEGER",
                     "runID",   "INTEGER") %>%
  mutate(
    table = "batchRuns",
    not_nulls = TRUE,
    extra = list(c("CREATE INDEX batchRuns_batchID on batchRuns (batchID)",
                   "CREATE INDEX batchRuns_runID on batchRuns (runID)"))) %>%
  bind_rows(t, .)


# clarified ------------------------------------------------------------------
t <- tribble(~column,   ~type,
                     "ambigID", "INTEGER",
                     "tagID",   "INTEGER",
                     "tsStart", "REAL",
                     "tsEnd",   "REAL") %>%
  mutate(
    table = "clarified",
    extra = list(c(
      paste0("CREATE INDEX IF NOT EXISTS clarified_ambigID_tsStart ",
             "ON clarified(ambigID, tsStart)")))) %>%
  bind_rows(t, .)


# filters ------------------------------------------------------------------
t <- tribble(
  ~column,        ~type,
  "filterID",     "INTEGER",  # locally unique filterID
  "userLogin",    "TEXT",     # motus login of the user who created the filter
  "filterName",   "TEXT",     # short name for the filter used by the user
  "motusProjID",  "INTEGER",  # project ID for shaing the filter with others
  "descr",        "TEXT",      # longer description of what the filter contains
  "lastModified", "TEXT") %>%  # date when the filter was last modified
  mutate(table = "filters",
         keys = column == "filterID",
         not_nulls = column %in% c("userLogin", "filterName", "motusProjID",
                                   "lastModified"),
         extra = list(c("CREATE UNIQUE INDEX IF NOT EXISTS 
                        filters_filterName_motusProjID ON filters 
                        (filterName ASC, motusProjID ASC)"))) %>%
  bind_rows(t, .)


# meta --------------------------------------------------------------------
t <- tribble(
  ~column,    ~type,
  "key",      "TEXT",     # name of key for meta data
  "val",      "TEXT") %>% # character giving meta data; might be in JSON format
  mutate(table = "meta", 
         keys = column == "key",
         not_nulls = column == "key",
         uniques= column == "key") %>%
  bind_rows(t, .)

# projs -------------------------------------------------------------------
t <- tribble(
  ~column,             ~type,
  "id",                 "INTEGER",
  "name",               "TEXT",
  "label",              "TEXT",
  "tagsPermissions",    "INTEGER",
  "sensorsPermissions", "INTEGER") %>%
  mutate(table = "projs", 
         keys = column == "id",
         not_nulls = column == "id") %>%
  bind_rows(t, .)
  



# projAmbig --------------------------------------------------------------------

t <- tribble(
  ~column,             ~type,
  "ambigProjectID",   "INTEGER", 
  "projectID1",       "INTEGER",
  "projectID2",       "INTEGER",
  "projectID3",       "INTEGER",
  "projectID4",       "INTEGER",
  "projectID5",       "INTEGER",
  "projectID6",       "INTEGER") %>%
  mutate(table = "projAmbig",
         keys = column == "ambigProjectID",
         not_nulls = column %in% c("ambigProjectID", "projectID1")) %>%
  bind_rows(t, .)
  
# projBatch --------------------------------------------------------------------
#
# Table for keeping track of which batches we already have, *by*
# tagDepProjectID, and which hits we already have therein. A single batch might
# require several records in this table:  an ambiguous tag detection has
# (negative) tagDepProjectID, which corresponds to a unique set of projects
# which might own the tag detection.

t <- tribble(
  ~column,           ~type,
  "tagDepProjectID", "INTEGER",     # project ID
  "batchID",         "INTEGER",     # unique identifier for batch
  "maxHitID",        "INTEGER") %>% # unique identifier for largest hit
                                    # we have for this tagDepProjectID, batchID
  mutate(table = "projBatch",
         keys = column %in% c("tagDepProjectID", "batchID"),
         not_nulls = TRUE) %>%
  bind_rows(t, .)


# recvs --------------------------------------------------------------------
t <- filter(t, table == "recvDeps") %>%
  filter(column %in% c("serno", "deviceID")) %>%
  select(-extra) %>%
  mutate(table = "recvs",
         keys = column == "deviceID",
         not_nulls = column == "deviceID") %>%
  bind_rows(t, .)


# runsFilter --------------------------------------------------------------
t <- tribble(
  ~column,       ~type,
  "filterID",    "INTEGER",  # locally unique filterID
  "runID",       "INTEGER",  # unique ID of the run to which the filter applies
  "motusTagID",  "INTEGER",  # unique ID of the Motus tag. Should match the 
                             # actual motusTagID, not the negative ambigID 
                             # in the case of ambiguous runs.
  "probability", "REAL") %>% # probability (normally between 0 and 1) 
                              # attached to the run record
  mutate(
    table = "runsFilters",
    keys = column %in% c("filterID", "runID", "motusTagID"),
    not_nulls = TRUE,
    extra = list(
    "CREATE INDEX IF NOT EXISTS 
     runsFilters_filterID_runID_motusTagID ON runsFilters 
     (filterID ASC, runID ASC, motusTagID ASC, probability ASC)")) %>%
  bind_rows(t, .)

# Consolidate lists
consolidate <- function(x) {
 if(any(is.null(x))) {
   x <- ""
 } else {
   x <- glue_collapse(x, sep = "; ")
   x <- glue("\n{x};", .trim = FALSE)
 }
  x
}


# ** COMBINE ---------------------------------------------------------------
sql_fields <- t %>%
  as_tibble() %>%
  mutate(type = case_when(str_detect(type, "INT|BIT") ~ "INTEGER",
                          str_detect(type, "VARCHAR") ~ "TEXT",
                          str_detect(type, "FLOAT|DECIMAL") ~ "REAL", 
                          TRUE ~ type)) %>%
  select(-ordinal_position, -is_nullable) %>%
  group_by(table) %>%
  mutate(keys = if_else(
    keys, 
    glue("PRIMARY KEY({glue_collapse(column[keys], sep = ',')})"), 
    ""),
    keys = tidyr::replace_na(keys, "")) %>%
  ungroup() %>%
  mutate(
    #most missing options get FALSE
    across(c(not_nulls, uniques), tidyr::replace_na, FALSE), 
    # Columns with special words are quoted
    column = if_else(column %in% c("group"), glue("'{column}'"), column),
    not_nulls = if_else(not_nulls, "NOT NULL", ""),
    uniques = if_else(uniques, "UNIQUE", ""),
    references = tidyr::replace_na(references, ""),
    references = if_else(references != "", glue("REFERENCES {references}"), ""),
    defaults = as.character(defaults),
    defaults = tidyr::replace_na(defaults, ""),
    defaults = if_else(defaults != "", glue("DEFAULT {defaults}"), ""),
    sql = glue("{column} {type} {not_nulls} {uniques} {defaults} {references}"),
    sql = str_replace_all(sql, "[ ]{2,}", " "),
    extra_sql = purrr::map_chr(extra, consolidate))

sql_tables <- sql_fields %>%
  group_by(table) %>%
  summarize(
    sql = glue_collapse(sql, sep = ',\n'),
    sql = if_else(any(keys != ""), glue("{sql},\n{keys[keys != ''][1]}"), sql),
    sql = glue("CREATE TABLE IF NOT EXISTS {table[1]} ({sql});",
               "{extra_sql[1]}"), 
    .groups = "drop")

sql_fields <- select(sql_fields, table, column, sql, extra_sql)
