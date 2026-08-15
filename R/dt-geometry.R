##############################
### Data type family: structured geometry
###############################
## Well-Known Text (WKT) geometry detector. Spatial geometries carry a very
## distinctive lexical signature (a geometry-type keyword followed by
## parenthesized coordinate lists), so they are detectable at the format level
## with low false-positive risk -- the strongest-reachability item in the
## aspirational `structured` family. WKB (hex) and GeoJSON (a JSON object with a
## "type"/"coordinates" schema) are separate representations left for later.


#' Is it a WKT (Well-Known Text) geometry?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a WKT geometry literal such as
#'   `POINT (30 10)` or `POLYGON ((...))`, optionally with a `Z`/`M`/`ZM`
#'   dimensionality tag. Matches the standard OGC geometry types.
#' @examples
#' is_wkt_geometry(c("POINT (30 10)", "LINESTRING (0 0, 1 1)", "banana", NA))
#' @family geometry detectors
#' @export
is_wkt_geometry <- function(x) {
  x <- as.character(x)
  types <- paste0("(POINT|LINESTRING|POLYGON|MULTIPOINT|MULTILINESTRING|",
                  "MULTIPOLYGON|GEOMETRYCOLLECTION|TRIANGLE|CIRCULARSTRING|",
                  "COMPOUNDCURVE|CURVEPOLYGON|MULTICURVE|MULTISURFACE)")
  out <- grepl(paste0("^\\s*", types, "\\s*(Z|M|ZM)?\\s*",
                      "(\\(.*\\)|EMPTY)\\s*$"), x, ignore.case = TRUE) &
         ## balanced-ish: must contain at least one digit inside (or be EMPTY)
         (grepl("\\d", x) | grepl("EMPTY\\s*$", x, ignore.case = TRUE))
  out[is.na(x)] <- NA
  out
}

#' Is it a GeoJSON geometry?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a JSON object carrying a GeoJSON `"type"`
#'   (`Point`, `Polygon`, `Feature`, `FeatureCollection`, ...) together with a
#'   `"coordinates"`, `"geometry"`, `"geometries"`, or `"features"` member.
#'   Structural (regex) check, not a full JSON parse.
#' @examples
#' is_geojson(c('{"type":"Point","coordinates":[30,10]}', "{}", NA))
#' @family geometry detectors
#' @export
is_geojson <- function(x) {
  x <- as.character(x)
  types <- paste0('"(Point|LineString|Polygon|MultiPoint|MultiLineString|',
                  'MultiPolygon|GeometryCollection|Feature|FeatureCollection)"')
  has_type    <- grepl(paste0('"type"\\s*:\\s*', types), x)
  has_payload <- grepl('"(coordinates|geometry|geometries|features)"\\s*:', x)
  out <- grepl("^\\s*\\{.*\\}\\s*$", x) & has_type & has_payload
  out[is.na(x)] <- NA
  out
}

#' Is it Well-Known Binary (WKB / EWKB) geometry?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a hex-encoded WKB string: an even-length
#'   hex value opening with a byte-order flag (`00` big-endian / `01`
#'   little-endian) whose 4-byte geometry-type field decodes to a base OGC type
#'   (1-7), tolerating ISO Z/M (`+1000/2000/3000`) and EWKB SRID/Z/M high-bit
#'   flags. The type check is what separates a real WKB blob from an arbitrary
#'   hex digest of the same length.
#' @examples
#' is_wkb(c("0101000000000000000000f03f000000000000f03f", NA))
#' @family geometry detectors
#' @export
is_wkb <- function(x) {
  x <- as.character(x)
  gate <- grepl("^(00|01)[0-9A-Fa-f]{8,}$", x) & (nchar(x) %% 2 == 0) &
          nchar(x) >= 42
  chk <- vapply(seq_along(x), function(i) {
    if (is.na(gate[i]) || !gate[i]) return(FALSE)
    s  <- x[i]
    le <- substr(s, 1, 2) == "01"
    bytes <- substring(substr(s, 3, 10), c(1, 3, 5, 7), c(2, 4, 6, 8))
    if (le) bytes <- rev(bytes)
    val <- strtoi(paste(bytes, collapse = ""), 16L)
    if (is.na(val)) return(FALSE)
    (val %in% 1:7) ||                    # plain 2D base type
      ((val %% 1000L) %in% 1:7) ||       # ISO Z/M/ZM (+1000/2000/3000)
      (bitwAnd(val, 255L) %in% 1:7)      # EWKB (base type in low byte, flags high)
  }, logical(1))
  out <- gate & chk
  out[is.na(x)] <- NA
  out
}
