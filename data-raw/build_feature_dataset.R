## data-raw/build_feature_dataset.R
## ---------------------------------------------------------------------------
## Build a unified, teachable feature matrix for type classification.
##
## One ROW per sample column, drawn from labeled corpora:
##   - Sherlock / VizNet  (data-raw/eval/sherlock/sherlock_test.rds)
##   - GitTables (dbpedia) (data-raw/eval/gittables/)
##   - formex-native positive examples (data-raw/datatypes/*.R)
## Each column is profiled into the 477 value-profile features produced by
## fx_extract_features(); the corpus label is mapped through the v4 crosswalks
## to the six ontology outcome columns requested for the lesson:
##   data_type, semantic_family, semantic_type, format_label, format_style, unit_type
##
## The six columns come from the GROUND-TRUTH crosswalk, NOT from running the
## package's own classifier -- so features -> label is a clean supervised task,
## not a mimic of guess_data_type(). format_label / format_style are v7
## format-rendering axes that these semantic corpora do not carry, so they are
## emitted as NA (kept for schema completeness).
##
## RUN from the package root:
##   Rscript data-raw/build_feature_dataset.R
## Optional env overrides: FX_MAX_SHERLOCK, FX_MAX_GITTABLES, FX_SEED
## ---------------------------------------------------------------------------

suppressMessages(pkgload::load_all(".", quiet = TRUE))

## --- config ----------------------------------------------------------------
MAX_SHERLOCK  <- as.integer(Sys.getenv("FX_MAX_SHERLOCK",  "150"))  # cols / sherlock type
MAX_GITTABLES <- as.integer(Sys.getenv("FX_MAX_GITTABLES", "60"))   # cols / gittables label
MIN_VALUES    <- 8     # a column needs at least this many non-missing values to profile
SEED          <- as.integer(Sys.getenv("FX_SEED", "514"))
OUT_STEM      <- "data-raw/type_features_dataset"

OUTCOME_COLS <- c("data_type", "semantic_family", "semantic_type",
                  "format_label", "format_style", "unit_type")

## --- v4 crosswalk -> six outcome columns -----------------------------------
## v4_type -> data_type, v4_class -> semantic_family, v4_subclass -> semantic_type,
## unit -> unit_type. format_label / format_style are not in the corpora (NA).
.na_blank <- function(x) { x <- trimws(as.character(x)); x[!nzchar(x)] <- NA; x }

load_crosswalk <- function(path, label_col) {
  cw <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  data.frame(
    source_label    = .na_blank(cw[[label_col]]),
    data_type       = .na_blank(cw$v4_type),
    semantic_family = .na_blank(cw$v4_class),
    semantic_type   = .na_blank(cw$v4_subclass),
    format_label    = NA_character_,
    format_style    = NA_character_,
    unit_type       = .na_blank(cw$unit),
    stringsAsFactors = FALSE
  )
}

sherlock_cw  <- load_crosswalk("data-raw/eval/sherlock-crosswalk-v4.csv",  "sherlock_type")
gittables_cw <- load_crosswalk("data-raw/eval/gittables-crosswalk-v4.csv", "gittables_label")

## formex-native detector names -> six outcome columns.
## Chain the shipped detector->old-triple crosswalk (.data_type_ontology) through
## the old->v4 ontology map; v4 == v7 vocab at (type, class, subclass). This
## resolves all 88 registered detectors to data_type / semantic_family /
## semantic_type. format_label / format_style / unit_type are left NA to keep the
## formex rows on the same schema as the semantic corpora.
build_formex_crosswalk <- function() {
  reg <- formex:::.data_type_ontology           # name -> c(data_type, subtype, class, format)
  m   <- utils::read.csv("data-raw/eval/ontology-old-to-v4-map.csv", stringsAsFactors = FALSE)
  key_old <- paste(m$old_type, m$old_subtype, m$old_class, sep = "\r")
  nms <- names(reg)
  do.call(rbind, lapply(nms, function(t) {
    o <- reg[[t]]
    j <- match(paste(o[1], o[2], o[3], sep = "\r"), key_old)
    data.frame(
      source_label    = t,
      data_type       = o[1],
      semantic_family = if (!is.na(j)) m$v4_class[j]    else NA_character_,
      semantic_type   = if (!is.na(j)) m$v4_subclass[j] else NA_character_,
      format_label    = NA_character_,
      format_style    = NA_character_,
      unit_type       = NA_character_,
      stringsAsFactors = FALSE
    )
  }))
}
formex_cw <- build_formex_crosswalk()

## --- parse Sherlock stringified python lists -------------------------------
parse_pylist <- function(s) {
  s <- as.character(s)
  toks <- regmatches(s, gregexpr("'([^']*)'|\"([^\"]*)\"", s))[[1]]
  if (length(toks)) return(gsub("^['\"]|['\"]$", "", toks))
  trimws(strsplit(gsub("^\\[|\\]$", "", s), ",")[[1]])
}

## --- collect (values, source_label, corpus) records ------------------------
collect_sherlock <- function() {
  sh <- readRDS("data-raw/eval/sherlock/sherlock_test.rds")
  labels <- as.character(sh$type)
  in_scope <- labels %in% sherlock_cw$source_label[!is.na(sherlock_cw$data_type)]
  idx <- which(in_scope)
  set.seed(SEED)
  keep <- unlist(lapply(split(idx, labels[idx]), function(ii)
    if (length(ii) > MAX_SHERLOCK) sample(ii, MAX_SHERLOCK) else ii))
  lapply(keep, function(i) list(values = parse_pylist(sh$values[i]),
                                source_label = labels[i], corpus = "sherlock"))
}

collect_gittables <- function() {
  dir <- "data-raw/eval/gittables"
  gt  <- utils::read.csv(file.path(dir, "dbpedia_gt.csv"),
                         stringsAsFactors = FALSE, check.names = FALSE)
  gt$table_file <- file.path(dir, "tables",
                             paste0(sub("_dbpedia$", "", gt$table_id), ".csv"))
  in_scope_labels <- gittables_cw$source_label[!is.na(gittables_cw$data_type)]
  gt <- gt[gt$annotation_label %in% in_scope_labels, , drop = FALSE]

  set.seed(SEED)
  keep <- unlist(lapply(split(seq_len(nrow(gt)), gt$annotation_label), function(ii)
    if (length(ii) > MAX_GITTABLES) sample(ii, MAX_GITTABLES) else ii))
  gt <- gt[keep, , drop = FALSE]

  tbl_cache <- new.env()
  read_tbl <- function(path) {
    key <- gsub("[^A-Za-z0-9]", "_", path)
    if (!is.null(tbl_cache[[key]])) return(tbl_cache[[key]])
    d <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                                  colClasses = "character"), error = function(e) NULL)
    assign(key, d, envir = tbl_cache); d
  }
  recs <- vector("list", nrow(gt))
  for (i in seq_len(nrow(gt))) {
    d <- read_tbl(gt$table_file[i]); if (is.null(d)) next
    colname <- paste0("col", gt$target_column[i])
    if (!colname %in% names(d)) next
    v <- d[[colname]]; v <- v[!is.na(v) & nzchar(trimws(v))]
    if (length(v) > 200) v <- v[seq_len(200)]
    recs[[i]] <- list(values = v, source_label = gt$annotation_label[i], corpus = "gittables")
  }
  recs[!vapply(recs, is.null, logical(1))]
}

collect_formex <- function() {
  env <- new.env()
  for (f in list.files("data-raw/datatypes", pattern = "\\.R$", full.names = TRUE))
    sys.source(f, envir = env)
  nms <- intersect(ls(env), formex_cw$source_label)   # only registered detectors
  recs <- lapply(nms, function(t) {
    v <- get(t, envir = env)
    if (!is.atomic(v)) return(NULL)
    list(values = as.character(v), source_label = t, corpus = "formex")
  })
  recs[!vapply(recs, is.null, logical(1))]
}

message("Collecting Sherlock columns ...")
recs <- collect_sherlock()
message(sprintf("  %d Sherlock columns", length(recs)))
message("Collecting GitTables columns ...")
recs <- c(recs, collect_gittables())
message("Collecting formex-native example columns ...")
recs <- c(recs, collect_formex())
message(sprintf("  %d columns total (all corpora)", length(recs)))

## drop columns too short to profile meaningfully. Count NON-SENTINEL values:
## a column that is all sentinels ("None", "UNK", "n/a", ...) is stripped to
## empty by prep_context and profiles to a degenerate 3-feature row, so it must
## clear the threshold on real values, not merely non-blank ones.
SENTINEL <- formex:::SENTINEL_NA
n_nonsentinel <- function(v) {
  v <- trimws(as.character(v)); v <- v[!is.na(v) & nzchar(v)]
  sum(!(tolower(v) %in% SENTINEL))
}
n_before <- length(recs)
recs <- Filter(function(r) n_nonsentinel(r$values) >= MIN_VALUES, recs)
message(sprintf("  dropped %d columns with < %d non-sentinel values; %d remain",
                n_before - length(recs), MIN_VALUES, length(recs)))

## --- extract features (col_name = NULL: no header leakage) ------------------
message("Extracting 477-feature profiles ...")
t0 <- Sys.time()
feat_rows <- vector("list", length(recs))
for (i in seq_along(recs)) {
  feat_rows[[i]] <- fx_extract_features(recs[[i]]$values, col_name = NULL)
  if (i %% 500 == 0)
    message(sprintf("  %d / %d (%.1f min elapsed)", i, length(recs),
                    as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}
## align columns (block gating can vary) and row-bind
all_nm <- unique(unlist(lapply(feat_rows, names)))
feat_rows <- lapply(feat_rows, function(r) {
  for (m in setdiff(all_nm, names(r))) r[[m]] <- NA_real_
  r[, all_nm, drop = FALSE]
})
features <- do.call(rbind, feat_rows)
message(sprintf("Feature matrix: %d rows x %d feature columns", nrow(features), ncol(features)))

## --- attach metadata + outcome labels --------------------------------------
## sample_values: up to 5 distinct non-missing values, joined by ';;'.
## vector_length: number of usable (non-missing, non-blank) values profiled.
usable_vals <- function(v) { v <- trimws(as.character(v)); v[!is.na(v) & nzchar(v)] }
sample5 <- function(v) paste(utils::head(unique(usable_vals(v)), 5), collapse = ";;")

meta <- data.frame(
  corpus        = vapply(recs, `[[`, character(1), "corpus"),
  source_label  = vapply(recs, `[[`, character(1), "source_label"),
  vector_length = vapply(recs, function(r) length(usable_vals(r$values)), integer(1)),
  sample_values = vapply(recs, function(r) sample5(r$values), character(1)),
  stringsAsFactors = FALSE
)
cw_all <- rbind(
  cbind(corpus = "sherlock",  sherlock_cw),
  cbind(corpus = "gittables", gittables_cw),
  cbind(corpus = "formex",    formex_cw)
)
key <- paste(meta$corpus, meta$source_label, sep = "\r")
cwk <- paste(cw_all$corpus, cw_all$source_label, sep = "\r")
m   <- match(key, cwk)
outcomes <- cw_all[m, OUTCOME_COLS, drop = FALSE]
rownames(outcomes) <- NULL

dataset <- cbind(meta, outcomes, features, stringsAsFactors = FALSE)

## --- report + persist -------------------------------------------------------
cat("\n=== dataset summary ===\n")
cat(sprintf("rows: %d   feature cols: %d   outcome cols: %d\n",
            nrow(dataset), ncol(features), length(OUTCOME_COLS)))
cat("\nrows per corpus:\n"); print(table(dataset$corpus))
cat("\ndata_type distribution:\n"); print(sort(table(dataset$data_type), decreasing = TRUE))
cat("\nn distinct semantic_type:", length(unique(dataset$semantic_type)), "\n")

utils::write.csv(dataset, paste0(OUT_STEM, ".csv"), row.names = FALSE, na = "")
saveRDS(dataset, paste0(OUT_STEM, ".rds"))
cat(sprintf("\nWrote %s.csv and %s.rds\n", OUT_STEM, OUT_STEM))
