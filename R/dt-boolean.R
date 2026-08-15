##############################
### Data type family: boolean
###############################
## A single indicator detector. Boolean columns are trivially recognizable at
## the value level -- a small two-state vocabulary -- but the specific boolean
## CLASS (indicator vs presence vs status vs eligibility) is a semantic role
## that values cannot reveal; that distinction needs the variable name or a
## codebook. So this emits the generic boolean/binary/indicator coordinate and
## is marked loose (its alphabet is tiny and 0/1 overlaps numeric codes).


#' Is it a boolean / indicator value?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a recognized two-state token
#'   (`true`/`false`, `t`/`f`, `yes`/`no`, `y`/`n`, `1`/`0`), case-insensitive.
#'   Whether the column is genuinely binary is a column-level property; this is
#'   a per-value membership test.
#' @examples
#' is_boolean(c("TRUE", "no", "Y", "0", "maybe", NA))
#' @family boolean detectors
#' @export
is_boolean <- function(x) {
  states <- c("true", "false", "t", "f", "yes", "no", "y", "n", "1", "0")
  x <- as.character(x)
  out <- tolower(trimws(x)) %in% states
  out[is.na(x)] <- NA
  out
}
