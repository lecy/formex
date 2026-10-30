## data-raw/wire_dark_detectors_boolean.R
## §6.1 / §6.2 wiring: give the implemented-but-dark leaves a SELECTIVE recipe
## so the always-on verifier can confirm them (the detectors already exist; only
## the ontology recipe + the always-on set were missing), declare the
## ISSN<->date_range shape collision via the cardinality disambiguator, and
## reconcile the stale `implemented` flags. Rewrites the CSV, validates, and
## rebuilds data/ontology.rda with the same reader the package uses.
## Run: Rscript data-raw/wire_dark_detectors_boolean.R
source("R/14-fx-ontology.R")

csv <- "inst/extdata/research_data_type_ontology_v7.csv"
o <- .fx_read_ontology_csv(csv)
set <- function(id, col, val) o[[col]][o$variant_id == id] <<- val

## --- §6.1: selective recipes for the dark color/web/postal/period leaves -----
set("n0041-f01", "raw_to_stable_transform", "{{ as_rgb }}")
set("n0042-f01", "raw_to_stable_transform", "{{ as_hsl }}")
set("n0043-f01", "raw_to_stable_transform", "{{ as_cmyk }}")
set("n0036-f01", "raw_to_stable_transform", "{{ as_ip }}")
set("n0037-f01", "raw_to_stable_transform", "{{ as_mac }}")
set("n0032-f01", "raw_to_stable_transform", "{{ as_po_box }}")
set("n0064-f01", "raw_to_stable_transform", "{{ as_month }}")
## (n0040 hex, n0039 phone, n0073-f05 issn already carry selective recipes.)

## --- §6.1: ISSN vs date_range shape collision (bare NNNN-NNNN) ----------------
## The discriminator is the ISSN CHECKSUM, not cardinality: a benchmark ISSN
## column repeats its few distinct values (low uniqueness), so a cardinality
## rule would wrongly prefer date_range. Instead as_range (R/20-fx-stabilize.R)
## yields a checksum-valid NNNN-NNNN to the issn leaf, exactly as it yields a
## YYYY-MM to month -- a recipe-level shape exclusion, so no collision_group is
## needed here (issn and date_range are different labels, so the validator does
## not require one). These stay blank:
set("n0073-f05", "collision_group", "")
set("n0073-f05", "disambiguator",   "")
set("n0070-f01", "collision_group", "")
set("n0070-f01", "disambiguator",   "")

## --- §6.2 + reconciliation: implemented flags --------------------------------
for (id in c("n0054-f01","n0055-f01","n0056-f01","n0057-f01","n0058-f01"))  # boolean binary
  set(id, "implemented", "yes")
set("n0027-f02", "implemented", "yes")   # last_name  (benchmark: hits)
set("n0027-f03", "implemented", "yes")   # full_name  (benchmark: hits)

probs <- fx_validate_ontology(o)
if (length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse = "\n  "))

utils::write.csv(o, csv, row.names = FALSE, quote = TRUE, na = "")
cat("wrote", csv, "\n")

## rebuild the lazy-loaded copy from the just-written CSV (keep the two in sync)
ontology <- .fx_read_ontology_csv(csv)
stopifnot(identical(ontology, o))

## mark the non-ASCII strings (euro-strip recipes, DMS coordinate examples) as
## UTF-8, matching data-raw/mark_utf8_data.R -- otherwise R CMD check raises
## "checking data for non-ASCII characters ... WARNING". The bytes are unchanged
## (fx_ontology() reads the CSV with the same bytes), so the CSV<->rda agreement
## test still holds: Encoding() marks a string, it does not alter its content.
mark_utf8 <- function(x) {
  if (is.character(x)) { Encoding(x) <- "UTF-8"; return(x) }
  if (is.list(x))      { x[] <- lapply(x, mark_utf8); return(x) }
  x
}
ontology <- mark_utf8(ontology)
if (!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2, compress = "xz")
tools::resaveRdaFiles("data/ontology.rda")
cat(sprintf("wrote data/ontology.rda: %d rows; integrity CLEAN; UTF-8 marked\n",
            nrow(ontology)))
