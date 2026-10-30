## data-raw/scaffold_gap_cases.R
## -------------------------------------------------------------------------
## Scaffold banked test cases for ontology variants that the frozen benchmark
## does NOT yet cover (zero cases in benchmark_full). The gap list is recomputed
## from the ontology + benchmark on every run, so this never hardcodes it.
##
## Value source, in priority order:
##   (1) a format-faithful detector fixture from data-raw/datatypes/*.R
##       (the richest honest values we have for each format), or
##   (2) a small seeded synthetic generator for numeric / temporal / boolean
##       variants that have no fixture.
## The ontology `examples` column is intentionally NOT used as the column: it
## holds 1-5 canonical tokens, too thin to profile or to pass triage.
##
## Each case is banked to dev/bank_v2 as a SCAFFOLD: label_method =
## "scaffold_synthetic", confidence "low", notes flagging it for review. The
## ontology coordinate (data_type/family/type/id/variant_id) is the gold label;
## a human/LLM review pass can confirm or relabel without touching the values.
##
## Run from the package root:  Rscript data-raw/scaffold_gap_cases.R
## Then rebuild the benchmark:  Rscript data-raw/build_benchmark.R
## -------------------------------------------------------------------------

suppressWarnings(suppressMessages(pkgload::load_all(".", quiet = TRUE)))

BANK_DIR  <- "dev/bank_v2"
CASE_BASE <- 900L          # scaffold case numbers start here (signals origin)
N_TARGET  <- 40L           # rows per scaffolded column (sampled from the pool)
SEED      <- 2026L

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L ||
                            (length(a) == 1L && is.na(a))) b else a

## ---- recompute the uncovered variant list --------------------------------
ont  <- fx_ontology()
full <- readRDS("inst/extdata/benchmark_full.rds")
lib_var <- unique(full$variant_id[!is.na(full$variant_id) & full$variant_id != ""])
ont_var <- ont$variant_id[!is.na(ont$variant_id) & ont$variant_id != ""]
GAP <- setdiff(sort(ont_var), sort(lib_var))

## ---- load the detector fixture vectors ------------------------------------
fx_env <- new.env()
for (f in list.files("data-raw/datatypes", pattern = "\\.R$", full.names = TRUE))
  sys.source(f, envir = fx_env)
fixt <- function(...) unname(unlist(mget(c(...), envir = fx_env)))

## ---- small seeded synthetic generators ------------------------------------
sq  <- function(a, b, n = N_TARGET) round(stats::runif(n, a, b), 4)
pick <- function(v, n = N_TARGET, prob = NULL) sample(v, n, replace = TRUE, prob = prob)

gen <- list(
  min_max = function() { lo <- round(stats::runif(N_TARGET, 0, 50)); hi <- lo + round(stats::runif(N_TARGET, 1, 50)); sprintf("%d to %d", lo, hi) },
  confidence_interval = function() { lo <- round(stats::runif(N_TARGET, -2, 3), 2); hi <- lo + round(stats::runif(N_TARGET, .1, 3), 2); sprintf("[%.2f, %.2f]", lo, hi) },
  lat = function() sprintf("%.4f", stats::runif(N_TARGET, -90, 90)),
  ## lat_lon: a DMS pair, latitude (N/S) first (format-faithful to n0018-f01).
  lat_lon = function() { tok <- function(mx, h) sprintf("%d° %02d' %02d\" %s", sample(0:mx,1), sample(0:59,1), sample(0:59,1), sample(h,1)); vapply(seq_len(N_TARGET), function(i) paste(tok(89, c("N","S")), tok(179, c("E","W")), sep=", "), character(1)) },
  ## lon_lat: a DMS pair, longitude (E/W) first then latitude (N/S) (n0019-f01).
  lon_lat = function() { tok <- function(mx, h) sprintf("%d° %02d' %02d\" %s", sample(0:mx,1), sample(0:59,1), sample(0:59,1), sample(h,1)); vapply(seq_len(N_TARGET), function(i) paste(tok(179, c("E","W")), tok(89, c("N","S")), sep=", "), character(1)) },
  hour_of_day  = function() as.character(pick(0:23)),
  week_of_year = function() as.character(pick(1:53)),
  month = function() pick(c(sprintf("2019%02d", 1:12), format(seq(as.Date("2019-01-01"), by="month", length.out=12), "%b %Y"))),
  balance = function() { v <- round(stats::runif(N_TARGET, -5000, 50000), 2); ifelse(runif(N_TARGET) < .4, formatC(v, format="f", digits=2, big.mark=","), sprintf("%.2f", v)) },
  ## euro: the symbol-bearing leaf -- the euro GLYPH is required (is_currency_amount
  ## keys on a symbol), prefix or suffix, EU grouping/decimal. A bare "EUR " code
  ## is NOT a currency amount at the value level, so it is not generated here.
  euro = function() { v <- round(stats::runif(N_TARGET, -500, 20000), 2); num <- formatC(v, format="f", digits=2, big.mark=".", decimal.mark=","); pre <- runif(N_TARGET) < .5; ifelse(pre, paste0("€", num), paste0(num, "€")) },
  rate = function() sprintf("%.2f", stats::runif(N_TARGET, 0, 100)),
  probability = function() sprintf("%.3f", stats::runif(N_TARGET, 0, 1)),
  odds = function() sprintf("%d:%d", sample(1:20, N_TARGET, TRUE), sample(1:20, N_TARGET, TRUE)),
  percentile = function() { p <- sample(1:99, N_TARGET, TRUE); ifelse(runif(N_TARGET) < .3, paste0(p, c("th","st","nd","rd")[pmin(((p%%10)+1),4)]), as.character(p)) },
  presence = function() pick(c("x", ""), prob = c(.6, .4)),
  status   = function() pick(c("active", "inactive")),
  response = function() pick(c("yes", "no")),
  mixed    = function() pick(c("yes", "no", "0", "1", "t", "f", "x", "")),
  likert   = function() pick(c("1=Strongly disagree","2=Disagree","3=Neutral","4=Agree","5=Strongly agree")),
  missingness_reason = function() pick(c("Refused","N/A","Don't know","Missing","Not applicable","Skipped")),
  unclassified = function() pick(c("???","--","#VALUE!","—","n/a","","?")),
  literal  = function() pick(c("40%","02168","(605) 348-9999","www.usa.com","$1,200","2019-03-01","ACME Corp")),
  color_name = function() pick(c("brown","hazel","blond","auburn","black","blue","green","gray","red","chestnut","amber")),
  key_value  = function() { k <- function() paste0(sample(letters, sample(1:3,1)), collapse=""); vapply(seq_len(N_TARGET), function(i) paste(sprintf("%s=%d", replicate(sample(2:3,1), k()), sample(1:99, 1)), collapse=";"), character(1)) },
  point   = function() sprintf("POINT(%d %d)", sample(0:100, N_TARGET, TRUE), sample(0:100, N_TARGET, TRUE)),
  polygon = function() { one <- function() { n <- sample(3:5,1); xs <- sample(0:50,n); ys <- sample(0:50,n); pts <- paste(xs, ys); sprintf("POLYGON((%s,%s))", paste(pts, collapse=","), pts[1]) }; vapply(seq_len(N_TARGET), function(i) one(), character(1)) },
  array   = function() pick(c("[1,2,3]","[[1,2],[3,4]]","[10,20,30,40]","[\"a\",\"b\"]","[1.5,2.5]","[]","[true,false]")),
  object  = function() pick(c('{"id":1,"name":"x"}','{"a":1,"b":2}','{"k":"v"}','{"lat":40.7,"lng":-74.0}','{"nested":{"k":"v"}}','{"ok":true,"n":3}','{"tags":["x","y"]}')),
  serialized = function() pick(c('{"a":1,"b":2}','a|b|c','{"k":"v"}','x;y;z','{"id":1}','1,2,3','key:val'))
)

## ---- crosswalk: variant_id -> value pool ----------------------------------
## Only variants present in GAP are actually banked; extras are harmless.
source_for <- list(
  n0040 = function() fixt("hex_color"),
  n0041 = function() fixt("rgb_color"),
  n0042 = function() fixt("hsl_color"),
  n0043 = function() fixt("cmyk_color"),
  n0036 = function() fixt("ipv4", "ipv6"),
  n0037 = function() fixt("mac"),
  n0039 = function() fixt("phone", "intl_phone"),
  n0032 = function() fixt("po_box")
)
## administrative id variants (n0073-f0x) resolve by variant, not by node id
admin_src <- list("n0073-f02" = "isbn", "n0073-f03" = "doi",
                  "n0073-f04" = "orcid", "n0073-f05" = "issn")
geo_src   <- list("n0046-f02" = "us_state", "n0046-f03" = "city_name",
                  "n0046-f04" = "county_fips")
person_src<- list("n0027-f02" = "last_name", "n0027-f03" = "full_name")

pool_for <- function(vid, node, stype) {
  if (!is.null(admin_src[[vid]]))  return(fixt(admin_src[[vid]]))
  if (!is.null(geo_src[[vid]]))    return(fixt(geo_src[[vid]]))
  if (!is.null(person_src[[vid]])) return(fixt(person_src[[vid]]))
  if (!is.null(source_for[[node]]))return(source_for[[node]]())
  if (!is.null(gen[[stype]]))      return(gen[[stype]]())
  NULL
}

## ---- bank each gap variant -------------------------------------------------
set.seed(SEED)
banked <- list(); skipped <- list(); i <- 0L
for (vid in GAP) {
  i <- i + 1L
  row <- ont[match(vid, ont$variant_id), ]
  node  <- row$semantic_type_id
  stype <- row$semantic_type

  local_seed <- SEED + i
  set.seed(local_seed)
  pool <- tryCatch(pool_for(vid, node, stype), error = function(e) NULL)
  if (is.null(pool) || !length(pool)) {
    skipped[[length(skipped)+1]] <- data.frame(variant_id = vid, semantic_type = stype,
      reason = "no fixture or generator", stringsAsFactors = FALSE); next }

  ## realistic column: sample ~N_TARGET draws (with replacement) from the pool
  x <- if (length(pool) >= N_TARGET) pool else sample(pool, N_TARGET, replace = TRUE)
  x <- x[!is.na(x)]
  if (sum(nzchar(trimws(x))) < 3) {
    skipped[[length(skipped)+1]] <- data.frame(variant_id = vid, semantic_type = stype,
      reason = "pool too thin after cleaning", stringsAsFactors = FALSE); next }

  tr <- fx_triage_field(x, expected_data_type = row$data_type)

  mc <- fx_make_test_case(
    x = x, case_number = CASE_BASE + i,
    data_type = row$data_type, semantic_family = row$semantic_family,
    semantic_type = stype, semantic_type_id = node, variant_id = vid,
    depth_labeled = 3L,
    label_confidence = "low", label_method = "scaffold_synthetic",
    label_notes = paste0("SCAFFOLD for zero-coverage variant; values are ",
      if (!is.null(gen[[stype]]) && is.null(source_for[[node]]) &&
          is.null(admin_src[[vid]]) && is.null(geo_src[[vid]]) &&
          is.null(person_src[[vid]])) "seeded-synthetic" else "detector-fixture",
      "; confirm or relabel before use."),
    difficulty = if (is.na(tr$difficulty)) "easy" else tr$difficulty,
    difficulty_rationale = paste("auto;", paste(tr$noise_markers, collapse = ",")),
    noise_markers = tr$noise_markers,
    corpus = "scaffold", corpus_version = "gap-fill-1",
    original_label = stype,
    ontology = NULL, ontology_version = "v6",
    ontology_status = "in_ontology",
    detector_exists = identical(as.character(row$implemented), "yes"),
    order_is_signal = FALSE,
    mutations_allowed = c("case_flip","whitespace_pad","inject_missing","inject_sentinel"),
    mutations_forbidden = c("digit_transpose","delimiter_swap","truncate"),
    mutation_target = "hard", outdir = BANK_DIR)

  banked[[length(banked)+1]] <- data.frame(
    case_id = mc$obj$case_id, variant_id = vid, semantic_type = stype,
    data_type = row$data_type, n = length(x), n_unique = length(unique(x)),
    verdict = tr$verdict, difficulty = mc$obj$difficulty$rating,
    stringsAsFactors = FALSE)
}

B <- if (length(banked)) do.call(rbind, banked) else data.frame()
S <- if (length(skipped)) do.call(rbind, skipped) else data.frame()

options(width = 200)
cat(sprintf("\n=== SCAFFOLD: %d gap variants -> %d banked, %d skipped ===\n",
            length(GAP), nrow(B), nrow(S)))
if (nrow(B)) { cat("\n-- banked --\n"); print(B, row.names = FALSE) }
if (nrow(S)) { cat("\n-- skipped --\n"); print(S, row.names = FALSE) }
cat("\nWrote", nrow(B), "scaffold cases to", BANK_DIR, "\n")
cat("Next: Rscript data-raw/build_benchmark.R  to fold them into the frozen set.\n")
