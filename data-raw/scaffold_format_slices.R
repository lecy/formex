## data-raw/scaffold_format_slices.R
## -------------------------------------------------------------------------
## Expand the benchmark test LIBRARY with "format-sliced" depth for the P0
## problem types surfaced by the benchmark review. Where scaffold_gap_cases.R
## banks ONE canonical case per previously-uncovered variant (closing COVERAGE),
## this banks SEVERAL cases per P0 variant -- one per distinct, coherent format
## SHAPE -- so the benchmark gains statistical power (n > 1 per type) and
## actually measures FORMAT DRIFT, the real failure surface, instead of one
## canonical form.
##
## Each case is a ~30-40 row column of a SINGLE shape. Values are drawn from the
## detector fixtures in data-raw/datatypes/*.R (sliced by shape with regex)
## where a shape is present there, and from small seeded generators for shapes
## the fixtures lack. Everything is POSITIVE, single-format columns -- no
## hard-negatives / confusables (a separate follow-up) and no relabelling of
## existing cases.
##
## Banking conventions mirror scaffold_gap_cases.R:
##   - ontology coordinate is the gold label (data_type/family/type/id/variant)
##   - label_method = "scaffold_format_slice", label_confidence = "low"
##   - label_notes + original_label + an injected label.format_label name the
##     exact shape, so slices are distinguishable downstream
##   - corpus = "scaffold_fmt", corpus_version = "format-slice-1"
##   - case_number range 1000+ so it never collides with existing dev/bank_v2
##   - difficulty from fx_triage_field(); mismatch verdicts (composite surface
##     forms like rgb()/hsl() that do not parse as their ontology data_type) are
##     expected and still banked, same as the gap scaffolder.
##
## Run from the package root:  Rscript data-raw/scaffold_format_slices.R
## Then rebuild the benchmark:  Rscript data-raw/build_benchmark.R
## -------------------------------------------------------------------------

suppressWarnings(suppressMessages(pkgload::load_all(".", quiet = TRUE)))

BANK_DIR  <- "dev/bank_v2"
CASE_BASE <- 1000L         # format-slice case numbers start here
N_TARGET  <- 34L           # rows per sliced column
SEED      <- 2026L

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L ||
                            (length(a) == 1L && is.na(a))) b else a

## ---- detector fixtures (shape pools we can slice) -------------------------
fx_env <- new.env()
for (f in list.files("data-raw/datatypes", pattern = "\\.R$", full.names = TRUE))
  sys.source(f, envir = fx_env)
fixt  <- function(...) unname(unlist(mget(c(...), envir = fx_env)))
slice <- function(vec, pattern) vec[grepl(pattern, vec, perl = TRUE)]

## sample a pool up to N_TARGET draws (with replacement); keep uniques first so
## short fixture pools still yield a varied column
mix <- function(..., n = N_TARGET) {
  pool <- unique(c(...))
  pool <- pool[!is.na(pool) & nzchar(pool)]
  if (!length(pool)) return(character(0))
  if (length(pool) >= n) sample(pool, n) else sample(pool, n, replace = TRUE)
}

## ---- primitive generators --------------------------------------------------
hexd  <- function(k, n = N_TARGET)            # n strings of k lowercase hex digits
  vapply(seq_len(n), function(i) paste0(sample(c(0:9, letters[1:6]), k, TRUE), collapse = ""), character(1))
chan  <- function(n = N_TARGET) sample(0:255, n, TRUE)
pct   <- function(n = N_TARGET) sample(0:100, n, TRUE)
deg   <- function(n = N_TARGET) sample(0:360, n, TRUE)
frac  <- function(n = N_TARGET) round(stats::runif(n, 0, 1), 2)
areacode <- function(n = N_TARGET) sample(200:999, n, TRUE)
exch  <- function(n = N_TARGET) sample(200:999, n, TRUE)
subsc <- function(n = N_TARGET) sample(0:9999, n, TRUE)
yr    <- function(n = N_TARGET) sample(1990:2024, n, TRUE)
mo    <- function(n = N_TARGET) sample(1:12, n, TRUE)
pick  <- function(v, n = N_TARGET, prob = NULL) sample(v, n, replace = TRUE, prob = prob)

## ---- shape registry: variant_id -> list(shape_label, gen) ------------------
## Each gen() returns a length-N_TARGET character column of ONE shape.
shapes <- list()

## --- text/color/hex (n0040-f01) -------------------------------------------
shapes[["n0040-f01"]] <- list(
  list("hex #RRGGBB",      function() mix(slice(fixt("hex_color"), "^#[0-9A-Fa-f]{6}$"), paste0("#", hexd(6, 40)))),
  list("hex #RGB (short)", function() mix(slice(fixt("hex_color"), "^#[0-9A-Fa-f]{3}$"), paste0("#", hexd(3, 40)))),
  list("hex RRGGBB (bare, no hash)", function() mix(hexd(6, 50))),
  list("hex 0xRRGGBB",     function() mix(paste0("0x", hexd(6, 50))))
)

## --- text/color/rgb (n0041-f01) -------------------------------------------
shapes[["n0041-f01"]] <- list(
  list("rgb r,g,b",        function() mix(slice(fixt("rgb_color"), "^[0-9]+,[0-9]+,[0-9]+$"), sprintf("%d,%d,%d", chan(40), chan(40), chan(40)))),
  list("rgb r, g, b (spaced)", function() mix(sprintf("%d, %d, %d", chan(), chan(), chan()))),
  list("rgb functional rgb(r,g,b)", function() mix(sprintf("rgb(%d,%d,%d)", chan(), chan(), chan())))
)

## --- text/color/hsl (n0042-f01) -------------------------------------------
shapes[["n0042-f01"]] <- list(
  list("hsl h, s%, l%",    function() mix(slice(fixt("hsl_color"), "%"), sprintf("%d, %d%%, %d%%", deg(40), pct(40), pct(40)))),
  list("hsl functional hsl(h,s%,l%)", function() mix(sprintf("hsl(%d,%d%%,%d%%)", deg(), pct(), pct())))
)

## --- text/color/cmyk (n0043-f01) ------------------------------------------
shapes[["n0043-f01"]] <- list(
  list("cmyk c,m,y,k (fractional 0-1)", function() mix(slice(fixt("cmyk_color"), "^[0-9.]+,[0-9.]+,[0-9.]+,[0-9.]+$"), sprintf("%.2f,%.2f,%.2f,%.2f", frac(40), frac(40), frac(40), frac(40)))),
  list("cmyk functional cmyk(c,m,y,k)", function() mix(sprintf("cmyk(%.2f,%.2f,%.2f,%.2f)", frac(), frac(), frac(), frac())))
)

## --- text/web/ip (n0036-f01) ----------------------------------------------
ipv6_full <- function(n = N_TARGET) vapply(seq_len(n), function(i) paste(hexd(4, 8), collapse = ":"), character(1))
ipv6_comp <- function(n = N_TARGET) {
  pats <- c("::1", "::", "fe80::%s:%s", "2001:db8::%s", "%s::%s", "::ffff:%s:%s")
  vapply(seq_len(n), function(i) {
    p <- sample(pats, 1); k <- lengths(regmatches(p, gregexpr("%s", p)))
    do.call(sprintf, c(list(p), as.list(hexd(4, k))))
  }, character(1))
}
shapes[["n0036-f01"]] <- list(
  list("ip IPv4 dotted",      function() mix(fixt("ipv4"), sprintf("%d.%d.%d.%d", chan(40), chan(40), chan(40), chan(40)))),
  list("ip IPv6 full",        function() mix(slice(fixt("ipv6"), "^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$"), ipv6_full(40))),
  list("ip IPv6 compressed",  function() mix(ipv6_comp(50)))
)

## --- text/web/mac (n0037-f01) ---------------------------------------------
mac_sep <- function(sep, n = N_TARGET) vapply(seq_len(n), function(i) paste(hexd(2, 6), collapse = sep), character(1))
mac_dot <- function(n = N_TARGET) vapply(seq_len(n), function(i) paste(hexd(4, 3), collapse = "."), character(1))
shapes[["n0037-f01"]] <- list(
  list("mac colon 01:23:45:67:89:ab",  function() mix(slice(fixt("mac"), ":"), mac_sep(":", 40))),
  list("mac hyphen 01-23-45-67-89-ab", function() mix(slice(fixt("mac"), "^[0-9A-Fa-f]{2}-"), mac_sep("-", 40))),
  list("mac dotted 0123.4567.89ab",    function() mix(mac_dot(50)))
)

## --- text/contact/phone (n0039-f01) ---------------------------------------
shapes[["n0039-f01"]] <- list(
  list("phone NANP dashed 510-577-3201",  function() mix(slice(fixt("phone"), "^[0-9]{3}-[0-9]{3}-[0-9]{4}$"), sprintf("%03d-%03d-%04d", areacode(40), exch(40), subsc(40)))),
  list("phone NANP parens (309) 647-1820", function() mix(slice(fixt("phone"), "^\\([0-9]{3}\\) "), sprintf("(%03d) %03d-%04d", areacode(40), exch(40), subsc(40)))),
  list("phone dotted 510.577.3201",       function() mix(slice(fixt("phone"), "^[0-9]{3}\\.[0-9]{3}\\.[0-9]{4}$"), sprintf("%03d.%03d.%04d", areacode(40), exch(40), subsc(40)))),
  list("phone E.164 +1-NXX-NXX-XXXX",     function() mix(sprintf("+1-%03d-%03d-%04d", areacode(), exch(), subsc()))),
  list("phone international +CC ...",      function() mix(fixt("intl_phone")))
)

## --- text/postal/po_box (n0032-f01) ---------------------------------------
shapes[["n0032-f01"]] <- list(
  list("po_box PO BOX 7002",   function() mix(sprintf("PO BOX %d",   sample(1:9999, 40, TRUE)))),
  list("po_box P.O. Box 7002", function() mix(sprintf("P.O. Box %d", sample(1:9999, 40, TRUE)))),
  list("po_box POB 7002",      function() mix(sprintf("POB %d",      sample(1:9999, 40, TRUE)))),
  list("po_box Box 7002",      function() mix(sprintf("Box %d",      sample(1:9999, 40, TRUE))))
)

## --- temporal/period/month (n0064-f01) ------------------------------------
shapes[["n0064-f01"]] <- list(
  list("month yyyymm (201903)",   function() mix(sprintf("%d%02d", yr(40), mo(40)))),
  list("month Mon YYYY (Mar 2019)", function() mix(sprintf("%s %d", month.abb[mo(40)], yr(40)))),
  list("month YYYY-MM (2019-03)", function() mix(sprintf("%d-%02d", yr(40), mo(40)))),
  list("month full name (March)", function() mix(month.name[mo(50)]))
)

## --- text/text/literal (n0022-f01) : heterogeneous passthrough catch-all --
## fewer slices; each column deliberately MIXES content kinds (%/zip/phone/url/
## text) -- that heterogeneity is the signal for the literal passthrough type.
lit_pool_a <- c("40%", "12%", "87%", "02168", "94110", "(605) 348-9999",
                "510-577-3201", "www.usa.com", "https://x.org", "ACME Corp",
                "$1,200", "2019-03-01", "N/A")
lit_pool_b <- c("3.5 stars", "#hashtag", "see note 4", "TBD", "ID-4471",
                "8%", "90210", "jane@x.com", "room 12B", "~approx", "n/a", "v2.1")
lit_pool_c <- c("red/blue", "1 of 3", "Q4", "$5", "50%", "P.O. Box 9",
                "+1-415-555-2671", "http://a.b", "misc.", "???", "lot 7", "x12")
shapes[["n0022-f01"]] <- list(
  list("literal mixed-content column A", function() mix(lit_pool_a)),
  list("literal mixed-content column B", function() mix(lit_pool_b)),
  list("literal mixed-content column C", function() mix(lit_pool_c))
)

## --- identifier/id/administrative : ISSN (n0073-f05) ----------------------
issn_plain <- function(n = N_TARGET) sprintf("%04d-%04d", sample(0:9999, n, TRUE), sample(0:9999, n, TRUE))
issn_check <- function(n = N_TARGET) sprintf("%04d-%03dX", sample(0:9999, n, TRUE), sample(0:999, n, TRUE))
shapes[["n0073-f05"]] <- list(
  list("issn NNNN-NNNN",        function() mix(slice(fixt("issn"), "[0-9]$"), issn_plain(40))),
  list("issn NNNN-NNNX (check digit X)", function() mix(slice(fixt("issn"), "X$"), issn_check(40))),
  list("issn ISSN NNNN-NNNN (prefixed)", function() mix(sprintf("ISSN %s", issn_plain(40))))
)

## --- boolean/binary/presence (n0055-f01) ----------------------------------
shapes[["n0055-f01"]] <- list(
  list("presence x / blank",        function() pick(c("x", ""),            prob = c(.6, .4))),
  list("presence 1 / blank",        function() pick(c("1", ""),            prob = c(.6, .4))),
  list("presence present / absent", function() pick(c("present", "absent")))
)

## --- boolean/binary/status (n0056-f01) ------------------------------------
shapes[["n0056-f01"]] <- list(
  list("status active / inactive",   function() pick(c("active", "inactive"))),
  list("status enabled / disabled",  function() pick(c("enabled", "disabled"))),
  list("status on / off",            function() pick(c("on", "off"))),
  list("status open / closed",       function() pick(c("open", "closed")))
)

## --- boolean/binary/response (n0057-f01) ----------------------------------
shapes[["n0057-f01"]] <- list(
  list("response yes / no",       function() pick(c("yes", "no"))),
  list("response Y / N",          function() pick(c("Y", "N"))),
  list("response true / false",   function() pick(c("true", "false"))),
  list("response T / F",          function() pick(c("T", "F"))),
  list("response 1 / 0",          function() pick(c("1", "0")))
)

## --- boolean/binary/mixed (n0058-f01) : several encodings within one column
shapes[["n0058-f01"]] <- list(
  list("mixed encodings column A", function() pick(c("yes", "no", "1", "0", "t", "f", "Y", "N"))),
  list("mixed encodings column B", function() pick(c("true", "false", "y", "n", "on", "off", "x", "")))
)

## --- number/currency/euro (n0011-f01) : euro GLYPH, EU grouping/decimal ----
## (sec 6.3) the euro leaf is symbol-based; is_currency_amount keys on the glyph.
eur_amt <- function(n = N_TARGET) formatC(round(stats::runif(n, -500, 50000), 2),
            format = "f", digits = 2, big.mark = ".", decimal.mark = ",")
shapes[["n0011-f01"]] <- list(
  list("euro suffix glyph (EU format)", function() mix(paste0(eur_amt(40), "€"))),
  list("euro prefix glyph",            function() mix(paste0("€", eur_amt(40)))),
  list("euro prefix glyph spaced",     function() mix(paste0("€ ", eur_amt(40))))
)

## --- number/coordinate (sec 6.3): DMS pairs, decimal pairs, ISO 6709 --------
dms_tok <- function(mx, h) sprintf("%d° %02d' %02d\" %s",
            sample(0:mx, 1), sample(0:59, 1), sample(0:59, 1), sample(h, 1))
## n0018-f01 lat_lon: DMS (N/S first, E/W second) + a western-hemisphere decimal
## pair (lat 24..49 > lon -124..-67, a DESCENDING comma pair = coordinate, not a range)
shapes[["n0018-f01"]] <- list(
  list("lat_lon DMS (N/S, E/W)", function()
    vapply(seq_len(N_TARGET), function(i)
      paste(dms_tok(89, c("N","S")), dms_tok(179, c("E","W")), sep = ", "), character(1))),
  list("lat_lon decimal (W hemisphere)", function()
    sprintf("%.6f, %.6f", stats::runif(N_TARGET, 24, 49), stats::runif(N_TARGET, -124, -67)))
)
## n0018-f02 lat_lon: ISO 6709 compact signed-decimal pair (lat then lon)
shapes[["n0018-f02"]] <- list(
  list("lat_lon ISO 6709 compact", function()
    sprintf("%+08.4f%+09.4f",  stats::runif(N_TARGET, -89, 89), stats::runif(N_TARGET, -179, 179))),
  list("lat_lon ISO 6709 slash", function()
    sprintf("%+08.4f%+09.4f/", stats::runif(N_TARGET, -89, 89), stats::runif(N_TARGET, -179, 179)))
)
## n0019-f01 lon_lat: DMS (E/W first, N/S second) + a decimal pair whose first
## component is unambiguously a longitude (|lon| > 90), lon first
shapes[["n0019-f01"]] <- list(
  list("lon_lat DMS (E/W, N/S)", function()
    vapply(seq_len(N_TARGET), function(i)
      paste(dms_tok(179, c("E","W")), dms_tok(89, c("N","S")), sep = ", "), character(1))),
  ## eastern hemisphere: lon (91..179) > lat (-85..85), a DESCENDING pair, so it
  ## is distinguishable from an ascending numeric range and routes to lon_lat.
  list("lon_lat decimal (E hemisphere, lon>lat)", function()
    sprintf("%.6f, %.6f", stats::runif(N_TARGET, 91, 179), stats::runif(N_TARGET, -85, 85)))
)

## ---- inject the exact shape into label.format_label (read by build_benchmark)
inject_format_label <- function(path, shape) {
  L <- readLines(path, encoding = "UTF-8", warn = FALSE)
  i <- grep('"variant_id"', L)[1]
  if (is.na(i)) return(invisible())
  indent  <- sub('(^\\s*).*', '\\1', L[i])
  newline <- sprintf('%s"format_label": "%s",', indent, gsub('"', '\\\\"', shape))
  writeLines(append(L, newline, after = i), path, useBytes = TRUE)
  invisible()
}

## ---- bank every slice ------------------------------------------------------
ont <- fx_ontology()
set.seed(SEED)
banked <- list(); skipped <- list(); counter <- 0L

for (vid in names(shapes)) {
  row   <- ont[match(vid, ont$variant_id), ]
  node  <- row$semantic_type_id
  stype <- row$semantic_type
  for (slc in shapes[[vid]]) {
    counter <- counter + 1L
    shape <- slc[[1]]; gen <- slc[[2]]
    set.seed(SEED + counter)
    x <- tryCatch(gen(), error = function(e) character(0))
    x <- x[!is.na(x)]
    if (length(x) < 8L) {
      skipped[[length(skipped) + 1L]] <- data.frame(variant_id = vid, shape = shape,
        reason = "pool too thin", stringsAsFactors = FALSE); next
    }

    tr <- tryCatch(fx_triage_field(x, expected_data_type = row$data_type),
                   error = function(e) list(verdict = "triage_error",
                     difficulty = NA_character_, noise_markers = character(0)))
    diff <- if (is.null(tr$difficulty) || is.na(tr$difficulty)) "easy" else tr$difficulty

    mc <- fx_make_test_case(
      x = x, case_number = CASE_BASE + counter,
      data_type = row$data_type, semantic_family = row$semantic_family,
      semantic_type = stype, semantic_type_id = node, variant_id = vid,
      depth_labeled = 3L,
      label_confidence = "low", label_method = "scaffold_format_slice",
      label_notes = paste0("format slice: ", shape,
                           " (positive single-shape column; confirm or relabel before use)"),
      difficulty = diff,
      difficulty_rationale = paste("auto;", paste(tr$noise_markers, collapse = ",")),
      noise_markers = tr$noise_markers,
      corpus = "scaffold_fmt", corpus_version = "format-slice-1",
      original_label = shape,
      ontology = NULL, ontology_version = "v6",
      ontology_status = "in_ontology",
      detector_exists = identical(as.character(row$implemented), "yes"),
      order_is_signal = FALSE,
      mutations_allowed = c("case_flip", "whitespace_pad", "inject_missing", "inject_sentinel"),
      mutations_forbidden = c("digit_transpose", "delimiter_swap", "truncate"),
      mutation_target = "hard", outdir = BANK_DIR)

    inject_format_label(mc$path, shape)

    banked[[length(banked) + 1L]] <- data.frame(
      case_id = mc$obj$case_id, variant_id = vid, shape = shape,
      data_type = row$data_type, n = length(x), n_unique = length(unique(x)),
      verdict = tr$verdict, difficulty = mc$obj$difficulty$rating,
      stringsAsFactors = FALSE)
  }
}

B <- if (length(banked)) do.call(rbind, banked) else data.frame()
S <- if (length(skipped)) do.call(rbind, skipped) else data.frame()

options(width = 200)
cat(sprintf("\n=== FORMAT SLICES: %d P0 variants -> %d cases banked, %d skipped ===\n",
            length(shapes), nrow(B), nrow(S)))
if (nrow(B)) {
  cat("\n-- per-variant slice counts --\n")
  print(as.data.frame(table(variant_id = B$variant_id)), row.names = FALSE)
  cat("\n-- banked --\n"); print(B, row.names = FALSE)
}
if (nrow(S)) { cat("\n-- skipped --\n"); print(S, row.names = FALSE) }
cat("\nWrote", nrow(B), "format-slice cases to", BANK_DIR, "\n")
cat("Next: Rscript data-raw/build_benchmark.R  to fold them into the frozen set.\n")
