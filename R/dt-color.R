##############################
### Data type family: color
###############################
## Detectors for hex, RGB, HSL, and CMYK color notations.


#' Is it a hex color?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for `#RGB` or `#RRGGBB`.
#' @examples
#' is_hex_color(c("#4d9cf8", "#fff", "4d9cf8", NA))
#' @family color detectors
#' @export
is_hex_color <- function(x) {
  x <- as.character(x)
  out <- grepl("^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$", x)
  out[is.na(x)] <- NA
  out
}

#' Is it an RGB triple?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for three comma-separated integers 0-255.
#' @examples
#' is_rgb_color(c("220,220,220", "128, 64, 32", "300,0,0", NA))
#' @family color detectors
#' @export
is_rgb_color <- function(x) {
  x <- as.character(x)
  ok <- grepl("^[0-9, ]+$", x)
  rng <- .field_check(x, ",", matrix(c(0, 0, 0, 255, 255, 255), ncol = 2))
  out <- ok & rng
  out[is.na(x)] <- NA
  out
}

#' Is it an HSL triple?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for `H, S%, L%` with hue 0-360 and S/L 0-100%.
#' @examples
#' is_hsl_color(c("195, 100%, 27%", "0, 0%, 0%", "195, 100, 27", NA))
#' @family color detectors
#' @export
is_hsl_color <- function(x) {
  x <- as.character(x)
  ok <- grepl("^\\s*\\d{1,3}\\s*,\\s*\\d{1,3}\\s*%\\s*,\\s*\\d{1,3}\\s*%\\s*$", x)
  y <- gsub("%", "", x)
  rng <- .field_check(y, ",", matrix(c(0, 0, 0, 360, 100, 100), ncol = 2))
  out <- ok & rng
  out[is.na(x)] <- NA
  out
}

#' Is it a CMYK quadruple?
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for four comma-separated values in 0-1.
#' @examples
#' is_cmyk_color(c("0.0,0.31,0.37,0.0", "1,1,1,1", "0,0,0", NA))
#' @family color detectors
#' @export
is_cmyk_color <- function(x) {
  x <- as.character(x)
  ok <- grepl("^[0-9., ]+$", x)
  rng <- .field_check(x, ",", matrix(c(0, 0, 0, 0, 1, 1, 1, 1), ncol = 2))
  out <- ok & rng
  out[is.na(x)] <- NA
  out
}


## ---------------------------------------------------------------------------
## Named colors (lexicon) -------------------------------------------------
## A curated set of common color WORDS, for columns like `hair_color` /
## `eye_color` whose values are color names rather than hex/rgb codes. The set
## unions three canonical bases -- the CSS/X11 named colors and R's own
## colors() cover standard colors but miss descriptive/hair-eye vocabulary, so
## a small curated group (blond, brunette, auburn, hazel, ...) is added. Kept to
## COMMON words for precision (a column that is mostly these is a color column).
## Lower-cased; matched case-insensitively.
.color_names <- c(
  ## CSS / X11 basic + extended (common subset)
  "black","white","gray","grey","silver","red","maroon","crimson","scarlet",
  "pink","rose","salmon","coral","orange","tangerine","peach","apricot","amber",
  "gold","golden","yellow","cream","ivory","beige","tan","khaki","brown","tawny",
  "chestnut","chocolate","coffee","mahogany","sienna","umber","ochre","rust",
  "bronze","copper","green","olive","lime","mint","emerald","jade","forest",
  "teal","cyan","aqua","aquamarine","turquoise","blue","navy","azure","cobalt",
  "cerulean","sapphire","indigo","periwinkle","purple","violet","lavender",
  "lilac","mauve","plum","magenta","fuchsia","orchid","burgundy","wine","ruby",
  "charcoal","slate","taupe","sand","mustard","chartreuse","hazel","hazelnut",
  ## hair / eye / descriptive colors not in the standard lists
  "blond","blonde","brunette","auburn","ginger","redhead","platinum","raven",
  "strawberry","honey","caramel","dirty blonde","salt and pepper","graying",
  "greying","dark","light","pale","deep","bright","dull","multicolor",
  "multicolored","multicoloured","rainbow","clear","transparent","translucent",
  "metallic","pearl","opal")

#' Is it a named color?
#'
#' Tests membership in a curated set of common color WORDS (CSS/X11 named colors
#' plus descriptive and hair/eye-color vocabulary). For columns whose values are
#' color names (`hair_color`, `eye_color`) rather than hex/rgb codes. The symbol
#' detectors ([is_hex_color()] etc.) handle coded colors; this one handles words.
#'
#' Compound values count too: a value whose parts are **all** color words
#' (`"brown, grey"`, `"blue-gray"`, `"dark brown"`) is a color, so hair/eye
#' columns that mix single and compound colors still read as colors. A
#' multi-word phrase that is itself in the lexicon (`"salt and pepper"`) is
#' matched whole first. Non-color fillers (`"none"`, `"unknown"`) are `FALSE`.
#'
#' @param x A character vector.
#' @return Logical vector; `TRUE` for a known color word or an all-color
#'   compound (case-insensitive), `FALSE` otherwise, `NA` where `x` is `NA`.
#' @examples
#' is_color_name(c("Brown", "brown, grey", "blue-gray", "Chicago", NA))
#' #> TRUE TRUE TRUE FALSE NA
#' @seealso [is_hex_color()], [guess_data_type()]
#' @family color detectors
#' @export
is_color_name <- function(x) {
  x <- as.character(x)
  one <- function(v) {
    if (is.na(v)) return(NA)
    w <- tolower(trimws(v))
    if (w %in% .color_names) return(TRUE)                      # whole value (incl. phrases)
    toks <- strsplit(gsub("[,/&-]|\\band\\b", " ", w), "\\s+")[[1]]
    toks <- toks[nzchar(toks)]
    length(toks) >= 1 && all(toks %in% .color_names)           # every part is a color
  }
  vapply(x, one, logical(1), USE.NAMES = FALSE)
}
