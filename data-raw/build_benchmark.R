# build_benchmark.R -- assemble the evaluation benchmark from the local
# dev/bank* test library. Neither dev/ nor data-raw/ ships (both .Rbuildignore'd),
# so this is a reproducible build step. It emits:
#
#   inst/extdata/benchmark_full.rds  the full set, BUNDLED with the package so
#                                    fx_benchmark_data(which = "full") is always
#                                    the most up-to-date set offline. Re-run this
#                                    script after ANY change to the bank or the
#                                    ontology to refresh the bundled copy.
#   inst/extdata/benchmark_mini.rds  a small (<1 MB) stratified subset for tests/CI.
#   dev/benchmark_full.rds           an identical copy of the full set, kept so it
#                                    can be uploaded as the optional remote
#                                    "refresh" release asset (fx_benchmark_data(
#                                    refresh = TRUE)); not required for the bundle.
#
# NOTE: the benchmark is still in development -- not yet frozen for published
# reference. Keep editing the framework here; the bundled copy tracks the bank.
#
# One row per banked column: the (capped) unique values + counts, the gold label
# at every ontology level, and gold_style / gold_unit joined from fx_ontology().
# Run:  Rscript data-raw/build_benchmark.R

suppressWarnings(suppressMessages({
  library(jsonlite)
  pkgload::load_all(".", quiet = TRUE)
}))

set.seed(1L)

MAX_UNIQUE               <- 50L   # cap unique values stored per case
SHERLOCK_CAP_PER_VARIANT <- 6L    # diversity-cap the noisy Sherlock tier
MINI_PER_DT_TIER         <- 8L    # stratified subsample size for the mini set
BENCHMARK_VERSION        <- "1.0.0"

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L ||
                             (length(a) == 1L && is.na(a))) b else a

## ---- read one banked JSON case into a flat record -------------------------
read_case <- function(f, tier) {
  j <- tryCatch(fromJSON(f, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(j) || is.null(j$values$data) || !length(j$values$data)) return(NULL)
  d    <- j$values$data
  vals <- vapply(d, function(z) as.character(z$value %||% NA_character_), character(1))
  cnts <- vapply(d, function(z) as.integer(z$count %||% 1L),             integer(1))
  keep <- !is.na(vals) & nzchar(vals)
  vals <- vals[keep]; cnts <- cnts[keep]
  if (!length(vals)) return(NULL)
  if (length(vals) > MAX_UNIQUE) {               # keep the most frequent values
    ord  <- order(-cnts)[seq_len(MAX_UNIQUE)]
    vals <- vals[ord]; cnts <- cnts[ord]
  }
  lab  <- j$label
  diff <- j$difficulty
  diff <- if (is.list(diff)) (diff$level %||% NA_character_) else (diff %||% NA_character_)
  data.frame(
    case_id         = as.character(j$case_id %||% basename(f)),
    tier            = tier,
    corpus          = as.character(j$source$corpus %||% tier),
    difficulty      = as.character(diff),
    data_type       = as.character(lab$data_type       %||% NA_character_),
    semantic_family = as.character(lab$semantic_family  %||% NA_character_),
    semantic_type   = as.character(lab$semantic_type    %||% NA_character_),
    variant_id      = as.character(lab$variant_id       %||% NA_character_),
    format_label    = as.character(lab$format_label     %||% NA_character_),
    method          = as.character(lab$method           %||% NA_character_),
    confidence      = as.character(lab$confidence       %||% NA_character_),
    n_unique        = length(vals),
    stringsAsFactors = FALSE
  ) -> row
  row$values <- list(vals)
  row$counts <- list(cnts)
  row
}

read_bank <- function(dir, tier) {
  if (!dir.exists(dir)) return(NULL)
  files <- list.files(dir, "\\.json$", full.names = TRUE)
  rows  <- lapply(files, read_case, tier = tier)
  do.call(rbind, Filter(Negate(is.null), rows))
}

## ---- farthest-point diversity cap within a variant -------------------------
diversity_cap <- function(df, cap) {
  if (nrow(df) <= cap) return(df)
  sigs <- lapply(df$values, function(v) tryCatch(fx_type_signature(v), error = function(e) NULL))
  ok   <- !vapply(sigs, is.null, logical(1))
  if (sum(ok) <= cap) return(df[ok, , drop = FALSE])
  df <- df[ok, , drop = FALSE]; sigs <- sigs[ok]
  chosen <- 1L                                   # seed with the first, add farthest
  while (length(chosen) < cap) {
    dmin <- vapply(seq_along(sigs), function(i) {
      if (i %in% chosen) return(-Inf)
      min(vapply(chosen, function(c)
        tryCatch(fx_signature_distance(sigs[[i]], sigs[[c]]), error = function(e) 0), numeric(1)))
    }, numeric(1))
    chosen <- c(chosen, which.max(dmin))
  }
  df[chosen, , drop = FALSE]
}

## ---- gold style / unit from the ontology (determinate values only) ---------
ont <- fx_ontology()
clean_unit <- function(u) {
  u <- trimws(as.character(u))
  u[is.na(u) | u == "" | grepl("[(;]", u)] <- NA_character_   # menus / blanks -> NA
  u
}
clean_style <- function(style, sem_type, fmt_label, dt, fam) {
  s <- trimws(as.character(style))
  placeholder <- is.na(s) | s == "" | s == sem_type | s == fmt_label | s == dt | s == fam
  datadep     <- sem_type %in% c("calendar", "timestamp", "clock", "time")  # value-derived
  s[placeholder | datadep] <- NA_character_
  s
}
join_gold <- function(df) {
  i <- match(df$variant_id, ont$variant_id)
  df$gold_style <- clean_style(ont$format_style[i], df$semantic_type,
                               df$format_label, df$data_type, df$semantic_family)
  df$gold_unit  <- clean_unit(ont$unit_type[i])
  df
}

## ---- mark non-ASCII strings UTF-8 so R CMD check stays quiet ---------------
mark_utf8 <- function(x) {
  if (is.character(x)) { Encoding(x) <- "UTF-8"; return(x) }
  if (is.list(x))      { x[] <- lapply(x, mark_utf8); return(x) }
  x
}

## ---- assemble --------------------------------------------------------------
message("reading clean banks ...")
clean <- rbind(read_bank("dev/bank_v2", "clean"),
               read_bank("dev/bank_temporal", "clean"))

message("reading + vetting Sherlock bank ...")
sher <- read_bank("dev/bank_sherlock_3k", "sherlock")
if (!is.null(sher)) {
  sher <- sher[!is.na(sher$variant_id) &
               (is.na(sher$confidence) | sher$confidence != "low"), , drop = FALSE]
  sher <- do.call(rbind, lapply(split(sher, sher$variant_id),
                                diversity_cap, cap = SHERLOCK_CAP_PER_VARIANT))
}

full <- rbind(clean, sher)
full <- full[!is.na(full$data_type) & !is.na(full$variant_id), , drop = FALSE]
full <- join_gold(full)
rownames(full) <- NULL
attr(full, "benchmark_version") <- BENCHMARK_VERSION
attr(full, "built_on")          <- as.character(Sys.Date())

## stratified mini: up to MINI_PER_DT_TIER cases per (data_type, tier)
mini <- do.call(rbind, lapply(
  split(full, interaction(full$data_type, full$tier, drop = TRUE)),
  function(d) d[sample(nrow(d), min(nrow(d), MINI_PER_DT_TIER)), , drop = FALSE]))
rownames(mini) <- NULL
attr(mini, "benchmark_version") <- BENCHMARK_VERSION
attr(mini, "built_on")          <- as.character(Sys.Date())

full <- mark_utf8(full); mini <- mark_utf8(mini)

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
## Bundle BOTH sets with the package so fx_benchmark_data() is current offline;
## keep an identical dev/ copy of the full set for the optional remote-refresh
## release asset. The bundled inst/extdata copy is the source of truth.
saveRDS(full, "inst/extdata/benchmark_full.rds", version = 2, compress = "xz")
saveRDS(mini, "inst/extdata/benchmark_mini.rds", version = 2, compress = "xz")
if (dir.exists("dev"))
  saveRDS(full, "dev/benchmark_full.rds", version = 2, compress = "xz")

message(sprintf("full: %d cases (%d clean / %d sherlock), %d data types, %d variants -> inst/extdata/benchmark_full.rds (%.0f KB)",
                nrow(full), sum(full$tier == "clean"), sum(full$tier == "sherlock"),
                length(unique(full$data_type)), length(unique(full$variant_id)),
                file.size("inst/extdata/benchmark_full.rds") / 1024))
message(sprintf("mini: %d cases -> inst/extdata/benchmark_mini.rds (%.0f KB)",
                nrow(mini), file.size("inst/extdata/benchmark_mini.rds") / 1024))
