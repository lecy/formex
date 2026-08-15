## data-raw/eval/run-sherlock-eval.R
## -------------------------------------------------------------------------
## Evaluate formex's VALUE detectors against the Sherlock / VizNet 78-type
## benchmark and write a per-class precision/recall report.
##
## SETUP (one time):
##   1. Get the data (MIT-licensed code; VizNet-derived values). Easiest via the
##      Sherlock repo's helper, which pulls a ~500MB zip from Google Drive:
##         pip install sherlock-project gdown
##         python -c "from sherlock.helpers import download_data; download_data()"
##      That yields data/data/raw/{train,val,test}_{values,labels}.parquet, where
##      each *_values row is a column's cell values (a list) and *_labels$type is
##      the semantic type. Point VALUES_PARQUET / LABELS_PARQUET below at the
##      test split (or copy those two files next to this script).
##   2. Reading parquet in R needs the 'arrow' package: install.packages("arrow").
##
## RUN (from the package root):
##   Rscript data-raw/eval/run-sherlock-eval.R
##
## NOTE: Sherlock's labels were derived from column headers, so this is a
## VALUE-ONLY eval (use_name = FALSE) -- the honest test for the value detectors.
## For the NAME classifier, use a corpus whose headers are independent of the
## labels (e.g. GitTables), then re-run with use_name = TRUE and real headers.
## -------------------------------------------------------------------------

## --- config ---------------------------------------------------------------
VALUES_PARQUET <- "data/data/raw/test_values.parquet"
LABELS_PARQUET <- "data/data/raw/test_labels.parquet"
MAX_PER_CLASS  <- 200      # subsample per Sherlock type to keep the run cheap
SEED           <- 514
REPORT_DIR     <- "data-types/eval-reports"

## --- load package + crosswalk ---------------------------------------------
if (!requireNamespace("arrow", quietly = TRUE))
  stop("Install 'arrow' to read the Sherlock parquet files: install.packages('arrow')")
suppressMessages(pkgload::load_all(".", quiet = TRUE))
source("data-raw/eval/sherlock-crosswalk.R")
crosswalk <- sherlock_crosswalk()

## --- read + reconstruct columns -------------------------------------------
## Each *_values entry is a column's cell values. arrow returns a list column
## when stored as a list, or a character (stringified Python list) otherwise;
## handle both.
parse_pylist <- function(v) {
  if (is.list(v)) return(as.character(v[[1]]))
  s <- as.character(v)
  toks <- regmatches(s, gregexpr("'([^']*)'|\"([^\"]*)\"", s))[[1]]
  if (length(toks)) return(gsub("^['\"]|['\"]$", "", toks))
  trimws(strsplit(gsub("^\\[|\\]$", "", s), ",")[[1]])
}

vals <- arrow::read_parquet(VALUES_PARQUET)
labs <- arrow::read_parquet(LABELS_PARQUET)
value_col <- if ("values" %in% names(vals)) "values" else names(vals)[ncol(vals)]
label_col <- if ("type" %in% names(labs)) "type" else names(labs)[ncol(labs)]

labels_all <- as.character(labs[[label_col]])
columns_all <- lapply(seq_len(nrow(vals)), function(i) parse_pylist(vals[[value_col]][i]))

## --- subsample per class (reproducible) -----------------------------------
set.seed(SEED)
keep <- unlist(lapply(split(seq_along(labels_all), labels_all), function(idx)
  if (length(idx) > MAX_PER_CLASS) sample(idx, MAX_PER_CLASS) else idx))
columns <- columns_all[keep]
labels  <- labels_all[keep]
message(sprintf("Scoring %d columns across %d Sherlock types (<= %d each).",
                length(columns), length(unique(labels)), MAX_PER_CLASS))

## --- evaluate + summarize -------------------------------------------------
res <- evaluate_columns(columns, labels, crosswalk, use_name = FALSE)
sm  <- eval_summary(res)

cat("\n=== OVERALL (value-only, in-scope columns) ===\n")
print(sm$overall, row.names = FALSE, digits = 3)
cat("\n=== PER-CLASS (by support) ===\n")
print(sm$by_class, row.names = FALSE, digits = 3)

## out-of-scope Sherlock types (no crosswalk row) -- report coverage honesty
oos <- setdiff(unique(labels), crosswalk$source_label)
if (length(oos))
  cat("\nSherlock types with no crosswalk row (excluded):",
      paste(sort(oos), collapse = ", "), "\n")

## --- persist --------------------------------------------------------------
if (!dir.exists(REPORT_DIR)) dir.create(REPORT_DIR, recursive = TRUE)
write.csv(res, file.path(REPORT_DIR, "sherlock-per-column.csv"), row.names = FALSE)
write.csv(sm$by_class, file.path(REPORT_DIR, "sherlock-by-class.csv"), row.names = FALSE)
saveRDS(sm, file.path(REPORT_DIR, "sherlock-summary.rds"))
message("\nWrote reports to ", REPORT_DIR, "/")
