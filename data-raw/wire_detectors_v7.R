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
csv <- "inst/extdata/research_data_type_ontology_v7.csv"
o   <- .fx_read_ontology_csv(csv)

set_recipe <- function(vid, expr) o$raw_to_stable_transform[o$variant_id == vid] <<- expr
set_recipe("n0067-f01", "{{ as_dow }}")
set_recipe("n0068-f01", "{{ as_moy }}")
set_recipe("n0029-f01", "lookup:place")   # place: {{ none }} leaks; lookup is selective
set_recipe("n0081-f01", "{{ as_wkt[point] }}")     # geometry/point   (is_wkt_geometry, keyword-gated)
set_recipe("n0082-f01", "{{ as_wkt[polygon] }}")   # geometry/polygon (is_wkt_geometry, keyword-gated)
## sec 6.3 coordinate pairs: replace the placeholder {{ as_coord[from:..][order:..] }}
## recipes (which the DSL cannot parse) with self-contained selective verbs.
set_recipe("n0018-f01", "{{ as_coord_latlon }}")      # number/coordinate/lat_lon (DMS or decimal)
set_recipe("n0018-f02", "{{ as_coord_latlon_iso }}")  # number/coordinate/lat_lon (ISO 6709)
set_recipe("n0019-f01", "{{ as_coord_lonlat }}")      # number/coordinate/lon_lat (DMS or decimal)

## usd: as_usd is now gated on is_currency_amount (a $-marked amount), so the
## recipe confirms selectively (confirm 1.00 / leak 0.00) on the 16 banked usd
## columns. euro (n0011-f01, sec 6.3) is the same selective mechanism
## (.fx_currency_amount with the euro glyph) and now ships banked cases, so it is
## wired too; it joins the always-on verifier set (no banked usd-style columns for
## the signature router to shortlist). balance (n0009-f01) stays implemented=no --
## it is symbol-less, hence metadata-gated, not value-detectable.
## coordinate lat_lon/lon_lat (n0018-f01/f02, n0019-f01, sec 6.3): the DMS and
## ISO 6709 PAIR forms are value-distinctive and ship selective as_coord_* verbs
## plus banked cases; they join the always-on set. Bare lat/lon (n0020/n0021)
## stay implemented=no (metadata-gated: a plain decimal is not value-typable).
## place (lookup:place, selective) and min_max range ({{ as_range }}, already
## selective -- the verb the implemented date_range uses) both have test cases.
## geometry point/polygon (is_wkt_geometry): high-precision and rare, so the
## router never shortlists them -- the geometry family is added to the verifier's
## always-on set in R/02-01-guess-data-type.R so as_wkt is confirmed regardless.
## Deliberately NOT wired (end-to-end blockers, see DEVELOPMENT-STATUS.md):
##  - collection/array (is_json): as_range is over-permissive and claims
##    "[[1,2],[3,4]]" as a min_max range -- a false positive to fix first.
##  - identifier/version (is_version), reporting_period: value-detectable in
##    isolation but the router does not surface them (too few training cases)
##    and they are not in the always-verify set, so they never route.
wired <- c("n0027-f01", "n0063-f01", "n0067-f01", "n0068-f01", "n0035-f01",
           "n0010-f01", "n0029-f01", "n0016-f01", "n0081-f01", "n0082-f01",
           "n0011-f01",                                  # euro (sec 6.3)
           "n0018-f01", "n0018-f02", "n0019-f01")        # coordinate pairs (sec 6.3)
o$implemented[o$variant_id %in% wired] <- "yes"

probs <- fx_validate_ontology(o)
if (length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse = "\n  "))

write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv)
if (!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2)

cat(sprintf("wired %d variants; implemented now %d / %d\n",
            length(wired), sum(o$implemented == "yes"), nrow(o)))
