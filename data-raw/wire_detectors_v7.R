## data-raw/wire_detectors_v7.R ------------------------------------------------
## Wire the highest-priority detectors that (a) have test cases in the library,
## (b) are backed by an existing is_* detector, and (c) pass the verifier's
## foil-selectivity gate (confirm >= 0.80, leak <= 0.25). Two need a detector-
## backed verb swap; the rest were already selective and only had a stale
## implemented=no flag. See DEVELOPMENT-STATUS.md for the inventory.
##
##   n0067 day_of_week    {{ as_ordered }} -> {{ as_dow }}   (is_day_of_week)
##   n0068 month_of_year  {{ as_ordered }} -> {{ as_moy }}   (is_month_of_year)
##   n0027-f01 first_name  recipe lookup:given  already selective
##   n0063 quarter         recipe {{ as_quarter }} already selective
##   n0035 domain          recipe {{ as_url }} already selective
##
## Run: Rscript data-raw/wire_detectors_v7.R    (idempotent)
## ---------------------------------------------------------------------------
source("R/14-fx-ontology.R")
csv <- "inst/extdata/research_data_type_ontology_v6.csv"
o   <- .fx_read_ontology_csv(csv)

set_recipe <- function(vid, expr) o$raw_to_stable_transform[o$variant_id == vid] <<- expr
set_recipe("n0067-f01", "{{ as_dow }}")
set_recipe("n0068-f01", "{{ as_moy }}")

## usd: as_usd is now gated on is_currency_amount (a $-marked amount), so the
## recipe confirms selectively (confirm 1.00 / leak 0.00) on the 16 banked usd
## columns. euro's verb is likewise selective but has no test cases, so it stays
## implemented=no until the library covers it.
wired <- c("n0027-f01", "n0063-f01", "n0067-f01", "n0068-f01", "n0035-f01", "n0010-f01")
o$implemented[o$variant_id %in% wired] <- "yes"

probs <- fx_validate_ontology(o)
if (length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse = "\n  "))

write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv)
if (!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2)

cat(sprintf("wired %d variants; implemented now %d / %d\n",
            length(wired), sum(o$implemented == "yes"), nrow(o)))
