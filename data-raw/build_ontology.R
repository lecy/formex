## data-raw/build_ontology.R
## Parse inst/extdata/research_data_type_ontology_v6.csv into the lazy-loaded
## data/ontology.rda, using the SAME reader the package uses (so the two agree),
## and validate integrity before saving. Run: Rscript data-raw/build_ontology.R
source("R/14-fx-ontology.R")

csv <- "inst/extdata/research_data_type_ontology_v6.csv"
ontology <- .fx_read_ontology_csv(csv)

probs <- fx_validate_ontology(ontology)
if(length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse="\n  "))

if(!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2)
cat(sprintf("wrote data/ontology.rda: %d rows, %d semantic types; integrity CLEAN\n",
            nrow(ontology), length(unique(ontology$semantic_type_id))))
