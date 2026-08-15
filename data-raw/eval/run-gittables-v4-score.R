## data-raw/eval/run-gittables-v4-score.R
## -------------------------------------------------------------------------
## Live feasibility scoring against the GitTables benchmark (CC BY 4.0, already
## downloaded to data-raw/eval/gittables/). Value-only (headers are anonymized).
## Produces a REVIEW SHEET with, per column: a value glimpse, which detectors
## fired, the prediction basis, the V4 prediction vs the feasible ideal, and the
## 0/1/2 feasibility score + unit flag.
##   Rscript data-raw/eval/run-gittables-v4-score.R
## -------------------------------------------------------------------------

DIR <- "data-raw/eval"; GT <- file.path(DIR, "gittables")
REPORT_DIR <- "data-types/eval-reports"
MAX_PER_LABEL <- 4; SEED <- 514

suppressMessages(pkgload::load_all(".", quiet = TRUE))
source(file.path(DIR, "v4-score-helpers.R"))
xwalk <- read.csv(file.path(DIR, "gittables-crosswalk-v4.csv"),
                  stringsAsFactors = FALSE, check.names = FALSE)

gt <- utils::read.csv(file.path(GT, "dbpedia_gt.csv"),
                      stringsAsFactors = FALSE, check.names = FALSE)
gt$table_file <- file.path(GT, "tables",
                           paste0(sub("_dbpedia$", "", gt$table_id), ".csv"))
gt <- gt[gt$annotation_label %in% xwalk$gittables_label, ]   # only crosswalked labels

## subsample per label first (so we only read the tables we need)
set.seed(SEED)
keep <- unlist(lapply(split(seq_len(nrow(gt)), gt$annotation_label), function(idx)
  if (length(idx) > MAX_PER_LABEL) sample(idx, MAX_PER_LABEL) else idx))
gt <- gt[sort(keep), ]

tbl_cache <- new.env()
read_tbl <- function(path) {
  key <- gsub("[^A-Za-z0-9]", "_", path)
  if (!is.null(tbl_cache[[key]])) return(tbl_cache[[key]])
  d <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                                colClasses = "character"), error = function(e) NULL)
  assign(key, d, envir = tbl_cache); d
}

columns <- list(); labels <- character()
for (i in seq_len(nrow(gt))) {
  d <- read_tbl(gt$table_file[i]); if (is.null(d)) next
  cn <- paste0("col", gt$target_column[i]); if (!cn %in% names(d)) next
  v <- d[[cn]]; v <- v[!is.na(v) & nzchar(trimws(v))]
  if (length(v) < 3) next
  columns[[length(columns) + 1L]] <- utils::head(v, 60)
  labels[length(labels) + 1L] <- gt$annotation_label[i]
}
message(sprintf("Scoring %d GitTables columns across %d labels.",
                length(columns), length(unique(labels))))

res <- score_columns_v4(columns, labels, xwalk, key_col = "gittables_label")
report_scores(res, "GitTables V4 feasibility scoring")

if (!dir.exists(REPORT_DIR)) dir.create(REPORT_DIR, recursive = TRUE)
utils::write.csv(res, file.path(REPORT_DIR, "gittables-v4-scored.csv"), row.names = FALSE)
message("\nWrote review sheet to ", file.path(REPORT_DIR, "gittables-v4-scored.csv"))
