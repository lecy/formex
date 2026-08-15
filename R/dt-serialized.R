##############################
### Data type family: serialized text
###############################
## Detects columns whose values are serialized data structures carried as text
## (a JSON object or array). This maps to text/block/serialized_text -- the raw
## string form; the parsed structured/record/object coordinate is a separate,
## post-parse concern. Marked loose in the ontology: GeoJSON is also valid JSON,
## so the specific is_geojson() detector should win the tie on spatial columns.


#' Is it a JSON object or array?
#'
#' Structural check (not a full parse): the trimmed value is delimited by
#' `{ }` with at least one `"key":` member, or by `[ ]`. Catches the common
#' "serialized structure in a cell" case; deeply malformed JSON that still has
#' the outer shape may pass, which is acceptable for column-level typing.
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a JSON object or array literal.
#' @examples
#' is_json(c('{"a":1,"b":[2,3]}', "[1,2,3]", "not json", NA))
#' @family serialized detectors
#' @export
is_json <- function(x) {
  x <- as.character(x)
  s <- trimws(x)
  obj <- grepl('^\\{\\s*".+"\\s*:.*\\}$', s)   # object with >= 1 "key": member
  arr <- grepl("^\\[.*\\]$", s) & nchar(s) >= 2 # array literal
  out <- obj | arr
  out[is.na(x)] <- NA
  out
}
