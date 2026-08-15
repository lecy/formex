##############################
### Data type family: person names
###############################
## Given-name, surname, and full-name detectors, matched against the internal
## SSA / Census frequency gazetteers in R/dt-name-data.R (.first_names,
## .last_names). Like is_city_name(), these are exact normalized-membership
## lookups over a HEAD list of common names -- high precision on the covered
## names, partial recall on rarer ones. They are marked loose in the ontology
## (.loose_detectors) because many common names are also ordinary English words
## ("May", "Grace", "Green", "Long"); guess_data_type() leans on the
## variable-name hint and specificity ranking to disambiguate.
##
## is_full_name() is the structural one: it requires a two-to-four token
## "First Last" (given-name led) or "Last, First" shape with at least one
## gazetteer hit, so it is not treated as loose.


#' Is it a common US given (first) name?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a single token matching the internal SSA
#'   given-name list (`.first_names`), case- and punctuation-insensitive.
#' @examples
#' is_first_name(c("James", "OLIVIA", "Xqzzy", NA))
#' @family person detectors
#' @export
is_first_name <- function(x) {
  x <- as.character(x)
  out <- .norm_name(x) %in% .first_names
  out[is.na(x)] <- NA
  out
}

#' Is it a common US surname (last name)?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a single token matching the internal
#'   Census surname list (`.last_names`), case- and punctuation-insensitive.
#' @examples
#' is_last_name(c("Smith", "garcia", "Xqzzy", NA))
#' @family person detectors
#' @export
is_last_name <- function(x) {
  x <- as.character(x)
  out <- .norm_name(x) %in% .last_names
  out[is.na(x)] <- NA
  out
}

#' Is it a person's full name?
#'
#' Recognizes `First [Middle] Last` (given-name led) and `Last, First [Middle]`
#' shapes of two to four tokens, requiring at least one token to be a known
#' given name or surname so arbitrary two-word phrases do not match. Middle
#' initials (`J.`) and internal punctuation are tolerated.
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a plausible full name.
#' @examples
#' is_full_name(c("John Smith", "Garcia, Maria", "Mary J. Cooper", "New York", NA))
#' @family person detectors
#' @export
is_full_name <- function(x) {
  x <- as.character(x)
  raw <- trimws(x)
  hit_first <- function(t) .norm_name(t) %in% .first_names
  hit_last  <- function(t) .norm_name(t) %in% .last_names
  out <- vapply(raw, function(s) {
    if (is.na(s) || !nzchar(s)) return(NA)
    comma <- grepl(",", s, fixed = TRUE)
    parts <- strsplit(trimws(gsub("[.,]", " ", s)), "\\s+")[[1]]
    parts <- parts[nzchar(parts)]
    if (length(parts) < 2 || length(parts) > 4) return(FALSE)
    if (comma) {
      ## "Last, First [Middle]"
      hit_last(parts[1]) || hit_first(parts[2])
    } else {
      ## "First [Middle] Last" -- given-name led
      hit_first(parts[1])
    }
  }, logical(1), USE.NAMES = FALSE)
  out[is.na(raw)] <- NA
  out
}
