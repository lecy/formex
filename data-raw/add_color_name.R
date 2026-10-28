## data-raw/add_color_name.R ---------------------------------------------------
## Add a named-color leaf (text/color/name) so color-WORD columns (hair_color,
## eye_color) route to a color type instead of leaking to geographic -- the
## color words "brown", "auburn", "orange" are also US place names, so without a
## color lexicon a color column tips to the geographic lexicon (datagoodr's
## starwars report). Backed by is_color_name() + the as_color_name verb.
## Clones the hex-color row as a template. Idempotent. Run:
##   Rscript data-raw/add_color_name.R
## ---------------------------------------------------------------------------
source("R/14-fx-ontology.R")
csv <- "inst/extdata/research_data_type_ontology_v6.csv"
o   <- .fx_read_ontology_csv(csv)

if (!"n0086-f01" %in% o$variant_id) {
  r <- o[o$variant_id == "n0040-f01", ][1, ]          # hex color = same text/color family
  r$semantic_type_id <- "n0086"; r$variant_id <- "n0086-f01"
  r$data_type <- "text"; r$semantic_family <- "color"; r$semantic_type <- "color_name"
  r$format_label <- "color_name"
  if ("format_style" %in% names(o))           r$format_style <- "name"
  if ("unit_type" %in% names(o))              r$unit_type <- ""
  if ("desired_default_format" %in% names(o)) r$desired_default_format <- ""
  if ("disambiguator" %in% names(o))          r$disambiguator <- ""
  if ("collision_group" %in% names(o))        r$collision_group <- ""
  r$match_kind               <- "lexicon"
  r$examples                 <- "brown ;; hazel ;; blond ;; auburn"
  r$data_format              <- "{{ color_name }}"
  r$raw_to_stable_transform  <- "{{ as_color_name }}"
  r$stable_format            <- "brown ;; hazel ;; blond"
  r$stable_import_rule       <- "{{ default:character }}"
  r$short_desc               <- "A named color (word), e.g. a hair or eye color."
  if ("detail" %in% names(o))         r$detail <- "A color given as a word rather than a code; matched against a curated color-name lexicon."
  if ("validation" %in% names(o))     r$validation <- "known color word"
  if ("default_storage" %in% names(o)) r$default_storage <- "character"
  r$implemented <- "yes"
  o <- rbind(o, r)
}

o$node_label <- .fx_derive_node_label(o)
probs <- fx_validate_ontology(o)
if (length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse = "\n  "))

write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv)
if (!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2)
cat(sprintf("ontology now %d rows; text/color/name present: %s\n",
            nrow(o), "n0086-f01" %in% o$variant_id))
