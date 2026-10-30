##############################
### Data type family: coordinate (geographic lat/lon)
###############################
## Detectors for the DISTINCTIVE, value-typable geographic coordinate forms: a
## degrees-minutes-seconds PAIR with N/S/E/W hemisphere letters, a decimal-degree
## PAIR (range-validated), and an ISO 6709 compact signed-decimal PAIR. These
## carry the signal in their surface form, so they confirm and route from values.
##
## A BARE single decimal latitude or longitude is deliberately NOT detected: a
## lone column of numbers in [-90, 90] is indistinguishable from a temperature, a
## score, or any other quantity without a header (the metadata-gated `lat` / `lon`
## case, DEVELOPMENT-STATUS.md Phase C). A value-only detector for it would only
## manufacture false leaves. A PAIR is different: two numbers in the lat/lon
## ranges, comma-separated, is a coordinate signal the value carries on its own.
##
## Disambiguation from a numeric range (min_max / confidence_interval): those are
## bracketed (`(a-b]`, `[a, b]`) or use `to` (`10 to 40`); a bare comma pair of
## two DECIMALS is not one of them. latitude is constrained to [-90, 90] and
## longitude to [-180, 180], which also tells lat_lon from lon_lat when one
## component exceeds 90 (only a longitude can).
##
## Each is_*() is an NA-safe logical predicate (character in -> logical out). The
## shared parser .fx_coord_canon() also backs the as_coord_* verbs in
## R/20-fx-stabilize.R, canonicalizing a match to a "lat, lon" decimal-degree
## string (latitude first). Degree symbol built from a code point so the source
## stays ASCII (U+00B0).

.fx_deg <- intToUtf8(0x00b0L)

## Format a validated lat/lon pair as the canonical "lat, lon" decimal string,
## or NA_character_ if out of range.
#' @keywords internal
#' @noRd
.fx_coord_fmt <- function(lat, lon){
  if (is.na(lat) || is.na(lon) || abs(lat) > 90 || abs(lon) > 180)
    return(NA_character_)
  paste0(formatC(lat, format = "f", digits = 6), ", ",
         formatC(lon, format = "f", digits = 6))
}

## Parse one DMS token (e.g. "40 deg 44' 55\" N") to list(dd, axis) or NULL.
## Minutes and seconds are optional; degrees may themselves be decimal.
#' @keywords internal
#' @noRd
.fx_dms_component <- function(tok){
  pat <- paste0("^\\s*(\\d{1,3}(?:\\.\\d+)?)\\s*", .fx_deg,
                "\\s*(?:(\\d{1,2})\\s*'\\s*(?:(\\d{1,2}(?:\\.\\d+)?)\\s*\"?)?)?",
                "\\s*([NSEWnsew])\\s*$")
  m <- regmatches(tok, regexec(pat, tok))[[1]]
  if (!length(m)) return(NULL)
  d  <- suppressWarnings(as.numeric(m[2])); if (is.na(d)) return(NULL)
  mi <- suppressWarnings(as.numeric(m[3])); if (is.na(mi)) mi <- 0
  se <- suppressWarnings(as.numeric(m[4])); if (is.na(se)) se <- 0
  hemi <- toupper(m[5])
  dd <- d + mi / 60 + se / 3600
  if (hemi %in% c("S", "W")) dd <- -dd
  list(dd = dd, axis = if (hemi %in% c("N", "S")) "lat" else "lon")
}

## Canonicalize ONE value to "lat, lon" decimal degrees for the requested KIND:
##  "latlon" / "lonlat" -> a DMS or decimal pair in that axis order
##  "iso"               -> an ISO 6709 compact signed-decimal pair (lat, lon)
## Returns NA_character_ when the value does not match that form. Range-validated.
#' @keywords internal
#' @noRd
.fx_coord_one <- function(v, kind){
  if (is.na(v)) return(NA_character_)
  v <- trimws(v)
  if (kind == "iso"){
    m <- regmatches(v, regexec(
      "^([+-]\\d{1,2}(?:\\.\\d+)?)([+-]\\d{1,3}(?:\\.\\d+)?)/?$", v))[[1]]
    if (!length(m)) return(NA_character_)
    return(.fx_coord_fmt(as.numeric(m[2]), as.numeric(m[3])))
  }
  parts <- strsplit(v, ",", fixed = TRUE)[[1]]
  if (length(parts) != 2) return(NA_character_)
  a <- .fx_dms_component(parts[1]); b <- .fx_dms_component(parts[2])
  if (!is.null(a) && !is.null(b)){                       # DMS pair
    want <- if (kind == "lonlat") c("lon", "lat") else c("lat", "lon")
    if (!(a$axis == want[1] && b$axis == want[2])) return(NA_character_)
    lat <- if (a$axis == "lat") a$dd else b$dd
    lon <- if (a$axis == "lon") a$dd else b$dd
    return(.fx_coord_fmt(lat, lon))
  }
  ## decimal pair: BOTH components must carry a decimal point (so an integer pair
  ## or a bare range like "10, 40" is not stolen), comma-separated, no brackets.
  dm <- regmatches(v, regexec(
    "^([+-]?\\d{1,3}\\.\\d+)\\s*,\\s*([+-]?\\d{1,3}\\.\\d+)$", v))[[1]]
  if (!length(dm)) return(NA_character_)
  n1 <- as.numeric(dm[2]); n2 <- as.numeric(dm[3])
  ## lat_lon: first is latitude. lon_lat: first is longitude, and only when it
  ## unambiguously exceeds the latitude range (|first| > 90), so a symmetric pair
  ## like "34.1, 40.2" resolves to lat_lon by convention rather than both.
  if (kind == "latlon" && abs(n1) <= 90  && abs(n2) <= 180) return(.fx_coord_fmt(n1, n2))
  if (kind == "lonlat" && abs(n1) <= 180 && abs(n2) <= 90 && abs(n1) > 90)
    return(.fx_coord_fmt(n2, n1))
  NA_character_
}

## Vectorized canonicalizer shared by the detectors below and the as_coord_*
## verbs. Returns the canonical "lat, lon" string per element, NA for non-matches.
#' @keywords internal
#' @noRd
.fx_coord_canon <- function(x, kind){
  x <- as.character(x)
  vapply(x, .fx_coord_one, character(1), kind = kind, USE.NAMES = FALSE)
}

#' Is it a latitude/longitude pair (latitude first)?
#'
#' Tests whether each element is a two-part geographic coordinate with latitude
#' first, in either degrees-minutes-seconds form with N/S/E/W hemisphere letters
#' (`"40 deg 44' 55\" N, 74 deg 00' 22\" W"`) or decimal-degree form
#' (`"34.0522, -118.2437"`). Latitude must be in `[-90, 90]` and longitude in
#' `[-180, 180]`.
#'
#' @param x A character vector of candidate values.
#' @return A logical vector: `TRUE` for a lat-first coordinate pair in range,
#'   `FALSE` otherwise, `NA` where `x` is `NA`.
#' @details A bracketed interval (`"[a, b]"`), a dashed/`to` range, a bare single
#'   number, or an integer comma pair (`"10, 40"`) is rejected. DMS axis order is
#'   read from the hemisphere letters; a decimal pair is latitude-first unless the
#'   first value exceeds 90 (see [is_coord_lonlat()]).
#' @seealso [is_coord_lonlat()], [is_iso6709()], [guess_data_type()]
#' @family coordinate detectors
#' @export
is_coord_latlon <- function(x){
  x <- as.character(x)
  out <- !is.na(.fx_coord_canon(x, "latlon"))
  out[is.na(x)] <- NA
  out
}

#' Is it a longitude/latitude pair (longitude first)?
#'
#' As [is_coord_latlon()] but longitude first, the GeoJSON axis order
#' (`"74 deg 00' 22\" W, 40 deg 44' 55\" N"`, or decimal `"-118.2437, 34.0522"`).
#' For a decimal pair this fires only when the first value unambiguously exceeds
#' the latitude range (`|first| > 90`), so a symmetric pair resolves to lat_lon.
#'
#' @param x A character vector of candidate values.
#' @return A logical vector: `TRUE` for a lon-first coordinate pair in range,
#'   `FALSE` otherwise, `NA` where `x` is `NA`.
#' @seealso [is_coord_latlon()], [is_iso6709()], [guess_data_type()]
#' @family coordinate detectors
#' @export
is_coord_lonlat <- function(x){
  x <- as.character(x)
  out <- !is.na(.fx_coord_canon(x, "lonlat"))
  out[is.na(x)] <- NA
  out
}

#' Is it an ISO 6709 lat/lon pair?
#'
#' Tests whether each element is an ISO 6709 compact signed-decimal coordinate
#' pair, latitude then longitude, e.g. `"+40.7128-074.0060"` or
#' `"-33.8688+151.2093/"`. Both components carry an explicit leading sign and
#' there is no internal separator (the second sign delimits the pair), which
#' keeps it distinct from a comma-separated range or decimal pair.
#'
#' @param x A character vector of candidate values.
#' @return A logical vector: `TRUE` for a valid ISO 6709 pair in range, `FALSE`
#'   otherwise, `NA` where `x` is `NA`.
#' @seealso [is_coord_latlon()], [is_coord_lonlat()], [guess_data_type()]
#' @family coordinate detectors
#' @export
is_iso6709 <- function(x){
  x <- as.character(x)
  out <- !is.na(.fx_coord_canon(x, "iso"))
  out[is.na(x)] <- NA
  out
}
