## ===========================================================================
## fx_roundtrip_check.R -- operationalizes the stabilization heuristic:
##
##   "Once transformed into its most stable version, will stats programs or
##    Excel guess the correct data type?"
##
## If yes, the stable format alone is sufficient. If no, the ontology row
## needs a stable_import_rule. This turns that judgment into a test that can
## be run across every row of the ontology automatically.
##
## Three distinct corruption mechanisms are checked separately, because the
## remedy differs for each:
##   VALUE_CHANGED  the characters themselves do not survive  (leading zeros)
##   TYPE_WRONG     characters survive but the inferred class is wrong
##   AMBIGUOUS      inferred correctly here, but a different reader or locale
##                  would infer differently (dd/mm vs mm/dd)
## ===========================================================================

## ---------------------------------------------------------------------------
## Reader simulations. base R is exact; the others are documented
## approximations -- Excel in particular cannot be reproduced faithfully, so
## treat excel_hazards() as a screen, not a verdict.
## ---------------------------------------------------------------------------

read_base <- function(values){
  tf <- tempfile(fileext = ".csv")
  write.csv(data.frame(v = values, stringsAsFactors = FALSE), tf, row.names = FALSE)
  back <- read.csv(tf, stringsAsFactors = FALSE)$v
  unlink(tf)
  list(values = as.character(back), class = class(back))
}

## readr / pandas style: stricter guessing, whole-column consistency required
read_guess <- function(values){
  v <- type.convert(values, as.is = TRUE)
  list(values = as.character(v), class = class(v))
}

## Excel screen. Not a simulation -- a list of known corruption triggers.
excel_hazards <- function(values){
  v <- values[!is.na(values)]
  h <- character(0)
  if(any(grepl("^0[0-9]+$", v)))
    h <- c(h, "leading_zeros_dropped")
  if(any(grepl("^[0-9]{16,}$", v)))
    h <- c(h, "precision_loss_15_digits")
  if(any(grepl("^[0-9]{1,2}[-/][0-9]{1,2}([-/][0-9]{2,4})?$", v)))
    h <- c(h, "coerced_to_date")
  ## the MAR1 / SEPT2 gene-symbol failure, and DNA-like short strings
  if(any(grepl("^(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[0-9]{1,2}$",
               toupper(v))))
    h <- c(h, "symbol_coerced_to_date")
  if(any(grepl("^[ACGT]{3,}$", toupper(v))))
    h <- c(h, "sequence_at_date_risk")
  ## leading "-" on a number is not formula injection -- only flag a minus
  ## that is not part of a numeric literal
  if(any(grepl("^[=+@]", v) | grepl("^-[^0-9.]", v)))
    h <- c(h, "formula_injection")
  if(any(grepl("^[0-9]+[eE][-+]?[0-9]+$", v)))
    h <- c(h, "scientific_notation_expansion")
  h
}

## ---------------------------------------------------------------------------
## fx_roundtrip_check()
##
##   stable_values     the values AFTER raw_to_stable_transform
##   intended_storage  from the ontology's default_storage column
## ---------------------------------------------------------------------------

STORAGE_CLASS <- list(
  character = "character", string = "character", factor = "character",
  integer   = "integer",   double = "numeric",   numeric = "numeric",
  logical   = "logical",   date   = "character", datetime = "character"
)

#' Check whether stabilized values survive a read/write round trip
#'
#' Reads a column of already-stabilized values back with both base and
#' type-guessing readers and reports whether the values change, the inferred
#' type is wrong, the readers disagree, or Excel hazards are present -- i.e.
#' whether an explicit import rule is required to preserve the intended storage.
#'
#' @param stable_values Character vector of stabilized values.
#' @param intended_storage The intended storage type (e.g. `"integer"`,
#'   `"factor"`, `"date"`).
#' @param id Optional identifier carried through to the result.
#' @return A one-row data frame flagging each hazard plus `needs_import_rule`.
#' @seealso [fx_audit_ontology()]
#' @export
fx_roundtrip_check <- function( stable_values, intended_storage, id = NA_character_ ){

  v  <- as.character(stable_values)
  rb <- read_base(v)
  rg <- read_guess(v)
  want <- STORAGE_CLASS[[tolower(intended_storage)]]
  if(is.null(want)) want <- NA_character_

  value_changed <- !identical(trimws(v), trimws(rb$values))
  type_wrong    <- !is.na(want) && !(want %in% rb$class)
  reader_disagree <- !identical(rb$class, rg$class)
  hz <- excel_hazards(v)

  ## factors and ordered categoricals can NEVER be inferred from values alone,
  ## so they always require a rule regardless of what the readers do
  always_rule <- tolower(intended_storage) %in% c("factor", "ordered", "date", "datetime")

  data.frame(
    id                = id,
    intended          = intended_storage,
    inferred_base     = paste(rb$class, collapse = "/"),
    inferred_guess    = paste(rg$class, collapse = "/"),
    value_changed     = value_changed,
    type_wrong        = type_wrong,
    reader_disagree   = reader_disagree,
    excel_hazards     = paste(hz, collapse = ";;"),
    needs_import_rule = value_changed || type_wrong || reader_disagree ||
                        always_rule || length(hz) > 0,
    reason            = paste(c(
                          if(value_changed)   "VALUE_CHANGED",
                          if(type_wrong)      "TYPE_WRONG",
                          if(reader_disagree) "READER_DISAGREE",
                          if(always_rule)     "NOT_INFERABLE_FROM_VALUES",
                          if(length(hz))      "EXCEL_HAZARD"), collapse = ";;"),
    stringsAsFactors  = FALSE
  )
}

## ---------------------------------------------------------------------------
## Run across an ontology file. Uses `examples` as a stand-in for stable
## values -- once stable_format is populated per row, point it there instead.
## ---------------------------------------------------------------------------

#' Round-trip audit an ontology file
#'
#' Runs [fx_roundtrip_check()] across every row of an ontology CSV, using a
#' value column (default `examples`) as a stand-in for stable values, and
#' returns which types need an explicit import rule to survive a read/write
#' round trip.
#'
#' @param path Path to an ontology CSV.
#' @param value_col Column holding `;;`-separated example values.
#' @return A data frame of per-row round-trip results with the ontology path.
#' @seealso [fx_roundtrip_check()]
#' @export
fx_audit_ontology <- function( path, value_col = "examples" ){
  d <- read.csv(path, stringsAsFactors = FALSE)
  ex <- lapply(strsplit(d[[value_col]], " *;; *"),
               function(z) z[nchar(trimws(z)) > 0])
  keep <- lengths(ex) > 0
  out <- do.call(rbind, Map(function(v, st, id) fx_roundtrip_check(v, st, id),
                            ex[keep], d$default_storage[keep], d$variant_id[keep]))
  cbind(out, path = paste(d$data_type, d$semantic_family, d$semantic_type,
                          sep = "/")[keep], stringsAsFactors = FALSE)
}
