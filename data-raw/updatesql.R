sql_versions <- dplyr::tibble()

sql_versions <- dplyr::mutate(sql_versions, 
                              date = lubridate::as_datetime(as.character(date), tz = "UTC"))

usethis::use_data(sql_versions, internal = TRUE, overwrite = TRUE)







