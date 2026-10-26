# Value-formatting helpers referenced from a DGF's `desired_data_import_rule` / `stable_data_format`
# columns. Each is applied element-wise to a single value, so they accept and
# return length-1 inputs and pass NA through unchanged. These are the built-in
# counterparts to user-supplied "polishing" functions such as dollarize().


#' Format a value as a canonical hyphenated EIN
#'
#' Normalizes an Employer Identification Number to the canonical `"NN-NNNNNNN"`
#' form, restoring a leading zero lost to numeric coercion. `NA` is returned
#' unchanged.
#'
#' @param x A single EIN value (numeric or character).
#'
#' @return A canonical EIN string `"NN-NNNNNNN"`, or `NA` if `x` is `NA`. Any
#'   non-digits (a prefix, an existing hyphen) are stripped first, and an
#'   8-digit value (a leading zero lost to numeric coercion) is zero-padded back
#'   to nine before the hyphen is inserted.
#' @seealso [as_mm()], [as_yyyy()], [as_yyyymm()]
#' @export
#' @importFrom stringr str_pad
as_EIN <- function(x) {
  if (is.na(x)) return(x)
  d <- gsub("\\D", "", as.character(x))
  if (!nchar(d) %in% c(8L, 9L)) return(NA_character_)
  d <- stringr::str_pad(d, 9, side = "left", pad = "0")
  paste0(substr(d, 1, 2), "-", substr(d, 3, 9))
}


#' Format a value as a zero-padded two-digit month
#'
#' Left-pads a month number to two digits (e.g. `8` becomes `"08"`). `NA` is
#' returned unchanged.
#'
#' @param x A single month value (numeric or character).
#'
#' @return A 2-character month string, or `NA` if `x` is `NA`.
#' @seealso [as_EIN()], [as_yyyy()], [as_yyyymm()]
#' @export
#' @importFrom stringr str_pad
as_mm <- function(x) {
  if (is.na(x)) return(x)
  stringr::str_pad(x, 2, side = "left", pad = "0")
}


#' Format a value as a four-digit year
#'
#' Coerces a year to character, warning if it has more than four digits. `NA`
#' is returned unchanged.
#'
#' @param x A single year value (numeric or character).
#'
#' @details A fiscal-year prefix (`"FY2019"`, `"FY 2019"`) is stripped and the
#'   embedded four-digit year returned. A value that already is a four-digit
#'   year passes through; anything else warns and is returned unchanged.
#' @return The four-digit year as a character string, or `NA` if `x` is `NA`.
#' @seealso [as_mm()], [as_yyyymm()]
#' @export
as_yyyy <- function(x) {
  if (is.na(x)) return(x)
  x <- trimws(as.character(x))
  y <- sub("^(?:FY|fy)\\s*", "", x)
  if (grepl("^(1[89]\\d{2}|20\\d{2})$", y)) return(y)
  if (max(nchar(x)) > 4) warning("YYYY elements have nchar > 4")
  x
}


#' Format a YYYYMM value as "YYYY-MM"
#'
#' Splits a six-character `YYYYMM` value into a hyphenated `"YYYY-MM"` string.
#' `NA` is returned unchanged.
#'
#' @param x A single `YYYYMM` value (numeric or character).
#'
#' @return A `"YYYY-MM"` character string, or `NA` if `x` is `NA`.
#' @seealso [as_yyyy()], [as_mm()]
#' @export
as_yyyymm <- function(x) {
  if (is.na(x)) return(x)
  x <- as.character(x)
  paste0(substr(x, 1, 4), "-", substr(x, 5, 6))
}
