##############################
### Classify by variable name (name-side detection)
###############################
## The name-based complement to guess_data_type(). classify_by_name() maps a
## column HEADER to an ontology class via .name_lexicon; guess_column() runs
## both the value detectors and the name classifier and reconciles them with a
## VALUES-FIRST policy: a confident value detector wins (values don't lie about
## their own format), and the name classifier only fills in when no value
## detector fires -- exactly the metadata-gated classes (weight, rate, estimate,
## boolean roles, ...) that values cannot reveal.


## normalize a header for lexicon matching: split camelCase, lowercase, collapse
## every run of non-alphanumerics to a single space, trim.
#' @keywords internal
#' @noRd
.tokenize_name <- function(name) {
  s <- as.character(name)
  s <- gsub("([a-z0-9])([A-Z])", "\\1 \\2", s)   # camelCase / PascalCase split
  s <- tolower(s)
  s <- gsub("[^a-z0-9]+", " ", s)                # separators -> space
  trimws(gsub("\\s+", " ", s))
}

## empty ontology vector in the standard shape
#' @keywords internal
#' @noRd
.na_ontology <- function() {
  stats::setNames(rep(NA_character_, 4L),
                  c("data_type", "data_subtype", "data_class", "data_format"))
}

#' Classify a column by its variable name
#'
#' Matches a column header against the internal name lexicon
#' (`.name_lexicon`) and returns the best-matching ontology class. This reaches
#' the metadata-gated classes that value detectors cannot -- it reads the name,
#' not the data -- so it is a *suggestion*, weaker than a value-signature match.
#'
#' @param name A single variable name (header string).
#' @param min_conf Minimum rule confidence for the top match to be reported as
#'   the guess; below it, `guess` is `NA`.
#'
#' @return A list with:
#'   \describe{
#'     \item{guess}{Best-matching class name, or `NA`.}
#'     \item{ontology}{Named vector `c(data_type, data_subtype, data_class,
#'       data_format)`; `data_format` is always `NA` (a name implies no format).}
#'     \item{confidence}{The matched rule's confidence.}
#'     \item{candidates}{Data frame of all matching rules, ranked by confidence.}
#'     \item{normalized}{The normalized header actually matched against.}
#'   }
#'
#' @examples
#' classify_by_name("hourly_wage")$guess          # currency
#' classify_by_name("respondent_weight")$guess    # weight
#' classify_by_name("is_active")$guess            # indicator
#' @seealso [guess_column()], [guess_data_type()]
#' @export
classify_by_name <- function(name, min_conf = 0.5) {
  norm <- if (length(name)) .tokenize_name(name[1]) else ""
  empty <- data.frame(class = character(0), data_type = character(0),
                      data_subtype = character(0), confidence = numeric(0),
                      rule = character(0), stringsAsFactors = FALSE)
  none <- list(guess = NA_character_, ontology = .na_ontology(),
               confidence = NA_real_, candidates = empty, normalized = norm)
  if (is.na(norm) || !nzchar(norm)) return(none)

  rows <- list()
  for (rule in .name_lexicon) {
    if (grepl(rule$pat, norm, ignore.case = TRUE)) {
      rows[[length(rows) + 1L]] <- data.frame(
        class = rule$coords[3], data_type = rule$coords[1],
        data_subtype = rule$coords[2], confidence = rule$conf, rule = rule$id,
        stringsAsFactors = FALSE)
    }
  }
  if (!length(rows)) return(none)

  cand <- do.call(rbind, rows)
  cand <- cand[order(-cand$confidence), , drop = FALSE]   # rule order preserved on ties
  cand <- cand[!duplicated(cand$class), , drop = FALSE]   # keep best per class
  rownames(cand) <- NULL

  top <- cand[1, ]
  guess <- if (top$confidence >= min_conf) top$class else NA_character_
  ontology <- stats::setNames(
    c(top$data_type, top$data_subtype, top$class, NA_character_),
    c("data_type", "data_subtype", "data_class", "data_format"))
  list(guess = guess, ontology = ontology, confidence = top$confidence,
       candidates = cand, normalized = norm)
}

#' Guess a column's type from its values and its name
#'
#' Runs both detection modalities and reconciles them VALUES-FIRST: if a value
#' detector clears `threshold`, its (format-anchored) answer is returned; only
#' when no value detector is confident does the name classifier fill in the
#' class. This is what lets the metadata-gated classes -- a `double` column
#' named `sampling_weight`, a `0/1` column named `eligible` -- be typed at all,
#' while never letting a misleading name override a real value signature.
#'
#' @param x A vector (coerced to character) of column values.
#' @param name Optional variable name (header string).
#' @param threshold Minimum value-detector pass rate to trust the value guess.
#' @param ... Passed to [guess_data_type()].
#'
#' @return A list with `source` (`"value"`, `"name"`, or `"none"`), `guess`,
#'   `ontology` (the standard 4-vector), `confidence`, and the full `value` and
#'   `name` sub-results for inspection.
#'
#' @examples
#' guess_column(c("06037", "36061"), name = "county")$source    # "value"
#' guess_column(c("3.4", "5.1", "7.8"), name = "sampling_weight")$guess  # weight
#' @seealso [guess_data_type()], [classify_by_name()]
#' @export
guess_column <- function(x, name = NULL, threshold = 0.8, ...) {
  vg <- guess_data_type(x, name = name, threshold = threshold, ...)
  ng <- classify_by_name(name)

  if (!is.na(vg$guess)) {
    return(list(source = "value", guess = vg$guess, ontology = vg$ontology,
                confidence = vg$confidence, value = vg, name = ng))
  }
  if (!is.na(ng$guess)) {
    return(list(source = "name", guess = ng$guess, ontology = ng$ontology,
                confidence = ng$confidence, value = vg, name = ng))
  }
  list(source = "none", guess = NA_character_, ontology = .na_ontology(),
       confidence = NA_real_, value = vg, name = ng)
}
