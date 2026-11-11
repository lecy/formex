## data-raw/make_imputation_spec.R
## ---------------------------------------------------------------------------
## Emit a per-feature NA-imputation rule for using the type-classification
## feature matrix in a conventional model (e.g. one-vs-rest logistic
## regression), where rows with any NA would otherwise be dropped.
##
## Rules (NA in fx_extract_features means "feature not applicable", never 0):
##   zero        : absence features -- the structure the feature measures is
##                 absent, so FALSE / 0-rate / 0-count is the correct value.
##                 (sequence flags on text, letter/digit/token/lexicon rates,
##                  punctuation-position spread, dispersion/shape of a constant
##                  column, regex checksums with no candidate.)
##   numeric_med : the numeric-summary block (num_*). NA because the column is
##                 not numeric. Impute the TRAIN median and rely on the always-
##                 present coerce_rate_strip as the "is-numeric" indicator, so a
##                 constant fill is not mistaken for a real measurement.
##   drop        : no information -- all-NA (nm_* header features, extracted
##                 with col_name = NULL) or constant (in_is_* input-class flags
##                 on character corpora). Remove before modelling.
##
## Writes data-raw/type_features_imputation.csv (feature, block, tier, na_rule).
## ---------------------------------------------------------------------------
suppressMessages(pkgload::load_all(".", quiet = TRUE))

man <- fx_feature_manifest()              # feature -> block -> tier

block_rule <- c(core = "zero", sequence = "zero", length = "zero",
                charclass = "zero", punct = "zero", mask = "zero",
                charfreq = "zero", regex = "zero", numeric = "numeric_med",
                token = "zero", lexicon = "zero", header = "drop")

man$na_rule <- unname(block_rule[man$block])

## special cases that override the block default -----------------------------
## the two always-present numeric gates are not NA and act as the indicator
man$na_rule[man$feature %in% c("coerce_rate_raw", "coerce_rate_strip",
                               "coerce_gap")] <- "zero"
## input-class flags are constant on character corpora -> drop
man$na_rule[grepl("^in_is_", man$feature)] <- "drop"
## n / pct_missing / pct_sentinel_na are always present
man$na_rule[man$feature %in% c("n", "pct_missing", "pct_sentinel_na")] <- "zero"

man <- man[order(match(man$block, names(block_rule)), man$feature), ]
utils::write.csv(man, "data-raw/type_features_imputation.csv", row.names = FALSE)

cat("features:", nrow(man), "\n\n")
cat("rule x block:\n")
print(table(man$na_rule, man$block))
cat("\nrule totals:\n"); print(table(man$na_rule))
cat("\nnumeric_med features (", sum(man$na_rule=="numeric_med"), "):\n", sep="")
print(man$feature[man$na_rule == "numeric_med"])
cat("\ndrop features (", sum(man$na_rule=="drop"), "):\n", sep="")
print(man$feature[man$na_rule == "drop"])
