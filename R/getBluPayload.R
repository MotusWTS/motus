#' Extract variables from BLUtag Payloads
#' 
#' Extracts the data from the hexadecimal BLUtag payload into new columns.
#'
#' @returns Data frame/Tibble of the BLUtag hits with extra variable columns.
#'
#' @inheritParams args
#' 
#' @export
#' @examples
#' # With example, dummy data
#' t <- data.frame(hitID = 99999999, batchID = 9999999, sync = 49000, product = 1, revision = 0)
#' t <- cbind(t, payload = c("6406060F", "6706150F", "6106270F", NA))
#' t 
#' 
#' # Extract payload
#' getBluPayload(t)
#' 
#' \dontrun{
#'   t <- tagme(XXX, update = TRUE, new = TRUE) # Hits with BLUTags
#'   getBluPayload(t) # Extract payload from the database
#'   getBluPayload(dplyr::tbl(t, "hitsBlu")) # Or supply the hitsBlu table directly
#' }

getBluPayload <- function(df_src) {

  hitsBlu <- check_df_src(
    df_src,
    cols = c("product", "revision", "payload"),
    view = "hitsBlu",
    collect = TRUE
  )
  
  by <- c("product", "revision", "payload")

  payload <- dplyr::select(hitsBlu, dplyr::all_of(by)) %>%
    dplyr::distinct() %>%
    dplyr::left_join(
      hitsBluPayloadRules(),
      by = c("product", "revision"),
      relationship = "many-to-many"
    ) %>%
    tidyr::drop_na()

  payload$payload_value <- purrr::pmap_dbl(payload, unpack_hex)
  
  payload <- payload %>%
    dplyr::select(dplyr::all_of(by), "variable", "payload_value") %>%
    tidyr::pivot_wider(names_from = "variable", values_from = "payload_value")

  dplyr::left_join(hitsBlu, payload, by = by)
}

#' Unpack hexadecimal data to numeric value
#' 
#' Converts hexadecimal bytes to raw, reads specific bytes given the rule, then
#' scales values accordingly.
#'
#' @param payload Character. Hexadecimal value.
#' @param start_byte Numeric. Starting byte from `histBluPayloadRules()`.
#' @param end_byte Numeric. Starting byte from `histBluPayloadRules()`.
#' @param scale Numeric. Scaling value from `histBluPayloadRules()`.
#' @param what See `readBin()`.
#' @param size See `readBin()`.
#' @param signed See `readBin()`.
#' @param endian See `readBin()`.
#' @param ... Unused. Captures unused values if run by pmap loop.
#'
#' @returns Numeric value
#'
#' @noRd
#' @examples
#' unpack_hex(
#'   "6406060F",
#'   start_byte = 1,
#'   end_byte = 2,
#'   scale = 0.001,
#'   size = 2,
#'   what = "integer",
#'   signed = FALSE,
#'   endian = "little"
#' )

unpack_hex <- function(
  payload,
  start_byte,
  end_byte,
  scale,
  size,
  what,  
  signed,
  endian,
  ...
) {
  raw <- as_raw(payload)[start_byte:end_byte]
  readBin(raw, what = what, size = size, signed = signed, endian = endian) *
    scale
}


#' Payload Rules for BLUtags
#' 
#' Hardcoded paylod rules for blutags. May be replaced with API call to dynamic
#' rules in future.
#'
#' @returns Tibble of payload rules used by [getBluPayload()].
#'
#' @noRd
#' @examples
#' hitsBluPayloadRules()

hitsBluPayloadRules <- function() {
  bin_args <- dplyr::tribble(
    ~method    , ~what     , ~signed , ~endian  ,
    "uint_le"  , "integer" , FALSE   , "little" ,
    "uint_be"  , "integer" , FALSE   , "big"    ,
    "int_le"   , "integer" , TRUE    , "little" ,
    "int_be"   , "integer" , TRUE    , "big"    ,
    "float_le" , "numeric" , TRUE    , "little" ,
    "float_be" , "numeric" , TRUE    , "big"
  )

  data.frame(
    product = c(1, 1, 2),
    revision = c(0, 0, 1),
    start_byte = c(1, 3, 1),
    end_byte = c(2, 4, 2),
    variable = c("solar_voltage", "temperature", "humidity"),
    method = c("uint_le", "uint_le", "uint_be"),
    scale = c(0.001, 0.01, 0.1)
  ) %>%
    dplyr::mutate(size = .data$end_byte - .data$start_byte + 1) %>%
    dplyr::left_join(bin_args, by = "method")
}
