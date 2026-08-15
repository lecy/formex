## data-raw/eval/run-gittables-eval.R
## -------------------------------------------------------------------------
## Evaluate formex against the GitTables column-type benchmark (Zenodo 5706316,
## CC BY 4.0). Tables are plain CSVs (no 'arrow' needed). Ground truth
## dbpedia_gt.csv maps (table_id, 0-based target_column) -> annotation_label.
##
## IMPORTANT / honesty: the benchmark's real headers are anonymized to
## col0..colN, and each annotation_label IS (derived from) the original header
## word. So this corpus supports:
##   (A) a VALUE-side eval (guess_data_type vs crosswalked gold) -- honest, a
##       second real corpus alongside Sherlock; and
##   (B) a NAME-lexicon COVERAGE probe -- classify_by_name(label) vs crosswalk.
##       Because the label doubles as the header here, (B) measures lexicon
##       COVERAGE of a real header vocabulary, NOT generalization accuracy.
##
## SETUP: files already downloaded to data-raw/eval/gittables/ (tables.zip
## unzipped to tables/). RUN from the package root:
##   Rscript data-raw/eval/run-gittables-eval.R
## -------------------------------------------------------------------------

DATA_DIR   <- "data-raw/eval/gittables"
REPORT_DIR <- "data-types/eval-reports"

suppressMessages(pkgload::load_all(".", quiet = TRUE))
source("data-raw/eval/gittables-crosswalk.R")
crosswalk <- gittables_crosswalk()

gt <- utils::read.csv(file.path(DATA_DIR, "dbpedia_gt.csv"),
                      stringsAsFactors = FALSE, check.names = FALSE)
gt$table_file <- file.path(DATA_DIR, "tables",
                           paste0(sub("_dbpedia$", "", gt$table_id), ".csv"))

## --- reconstruct one column vector per annotation (cache table reads) -------
tbl_cache <- new.env()
read_tbl <- function(path) {
  key <- gsub("[^A-Za-z0-9]", "_", path)
  if (!is.null(tbl_cache[[key]])) return(tbl_cache[[key]])
  d <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE,
                                check.names = FALSE, colClasses = "character"),
                error = function(e) NULL)
  assign(key, d, envir = tbl_cache)
  d
}

columns <- vector("list", nrow(gt)); labels <- character(nrow(gt)); ok <- logical(nrow(gt))
for (i in seq_len(nrow(gt))) {
  d <- read_tbl(gt$table_file[i])
  if (is.null(d)) next
  colname <- paste0("col", gt$target_column[i])
  if (!colname %in% names(d)) next
  v <- d[[colname]]
  v <- v[!is.na(v) & nzchar(trimws(v))]
  if (!length(v)) next
  columns[[i]] <- v; labels[i] <- gt$annotation_label[i]; ok[i] <- TRUE
}
columns <- columns[ok]; labels <- labels[ok]
## truncate very long columns (guess_data_type samples internally anyway)
columns <- lapply(columns, function(v) if (length(v) > 80) v[seq_len(80)] else v)
## subsample per label to keep the run cheap and balanced
MAX_PER_LABEL <- 40; SEED <- 514
set.seed(SEED)
keep <- unlist(lapply(split(seq_along(labels), labels), function(idx)
  if (length(idx) > MAX_PER_LABEL) sample(idx, MAX_PER_LABEL) else idx))
columns <- columns[keep]; labels <- labels[keep]
message(sprintf("Reconstructed + sampled %d columns (%d distinct labels, <=%d each).",
                length(columns), length(unique(labels)), MAX_PER_LABEL))

## ==========================================================================
## (A) VALUE-side eval (honest)
## ==========================================================================
res <- evaluate_columns(columns, labels, crosswalk, use_name = FALSE)
sm  <- eval_summary(res)
cat("\n=== (A) VALUE-ONLY eval vs GitTables gold (in-scope columns) ===\n")
print(sm$overall, row.names = FALSE, digits = 3)
cat("\n--- per class (by support) ---\n")
print(sm$by_class, row.names = FALSE, digits = 3)

in_scope_lab <- crosswalk$source_label
oos <- setdiff(unique(labels), in_scope_lab)
cat(sprintf("\nOut-of-scope labels excluded: %d of %d columns (%s ...)\n",
            sum(labels %in% oos), length(labels),
            paste(utils::head(sort(unique(oos)), 8), collapse = ", ")))

## ==========================================================================
## (B) NAME-lexicon COVERAGE probe (label doubles as header -> coverage, not acc)
## ==========================================================================
distinct <- sort(unique(labels[labels %in% in_scope_lab]))
probe <- do.call(rbind, lapply(distinct, function(lab) {
  gold <- crosswalk$data_class[match(lab, crosswalk$source_label)]
  cl <- classify_by_name(lab)
  data.frame(label = lab, gold_class = gold,
             lexicon_guess = ifelse(is.na(cl$guess), NA, cl$guess),
             fired = !is.na(cl$guess),
             agrees = !is.na(cl$guess) && cl$guess == gold,
             stringsAsFactors = FALSE)
}))
cat("\n=== (B) NAME-lexicon coverage over real header words ===\n")
cat(sprintf("labels probed: %d | lexicon fires on: %d (%.0f%%) | of those, agree with crosswalk: %d (%.0f%%)\n",
            nrow(probe), sum(probe$fired), 100*mean(probe$fired),
            sum(probe$agrees), 100*sum(probe$agrees)/max(1,sum(probe$fired))))
cat("labels the lexicon MISSED (coverage gaps):",
    paste(probe$label[!probe$fired], collapse = ", "), "\n")

## --- persist --------------------------------------------------------------
if (!dir.exists(REPORT_DIR)) dir.create(REPORT_DIR, recursive = TRUE)
write.csv(res,   file.path(REPORT_DIR, "gittables-per-column.csv"), row.names = FALSE)
write.csv(sm$by_class, file.path(REPORT_DIR, "gittables-by-class.csv"), row.names = FALSE)
write.csv(probe, file.path(REPORT_DIR, "gittables-name-coverage.csv"), row.names = FALSE)
message("\nWrote reports to ", REPORT_DIR, "/")
