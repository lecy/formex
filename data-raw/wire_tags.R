## data-raw/wire_tags.R --------------------------------------------------------
## Wire the categorical/multiselect/tags leaf (datagoodr starwars report: list
## columns collapsed to "a|b|c" were unrecognized). A flat delimited set is a
## `tags` value, not `structured` (which is for bracketed JSON/arrays). Backed
## by is_tags() + the as_tags verb; the leaf joins the verifier's always-on set
## (R/02-01) since the router is too sparse to shortlist it. Idempotent.
##   Rscript data-raw/wire_tags.R
## ---------------------------------------------------------------------------
source("R/14-fx-ontology.R")
csv <- "inst/extdata/research_data_type_ontology_v6.csv"
o   <- .fx_read_ontology_csv(csv)

o$raw_to_stable_transform[o$variant_id == "n0049-f01"] <- "{{ as_tags }}"
o$match_kind[o$variant_id == "n0049-f01"]              <- "mask"   # structural (a delimiter), not metadata
o$implemented[o$variant_id == "n0049-f01"]             <- "yes"

o$node_label <- .fx_derive_node_label(o)
probs <- fx_validate_ontology(o)
if (length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse = "\n  "))

write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv)
if (!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2)
cat(sprintf("tags wired; implemented now %d / %d\n", sum(o$implemented == "yes"), nrow(o)))
