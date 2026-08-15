## data-raw/split_administrative.R -------------------------------------------
## Recipe-granularity fix: the identifier/id/administrative catch-all (n0073) had
## one recipe (as_ein), but real administrative-id columns are ISBN/DOI/ORCID/ISSN
## etc. Split it into one variant row per id family, each with its own recipe.
## Re-derives node_label, validates, rebuilds data/ontology.rda. Idempotent.
source("R/14-fx-ontology.R")
csv <- "inst/extdata/research_data_type_ontology_v6.csv"
o   <- .fx_read_ontology_csv(csv)

base <- o[o$semantic_type_id == "n0073", ][1, ]
o    <- o[o$semantic_type_id != "n0073", , drop = FALSE]
mk <- function(vno, fields){ r <- base; r$variant_id <- sprintf("n0073-f%02d", vno)
  r$version_added <- "v6"; r$change_note <- "administrative split into id-family recipes"
  for (k in names(fields)) r[[k]] <- fields[[k]]; r }

rows <- list(
  mk(1, list(format_label="ein",   data_format="{{ gov:ein }}", raw_to_stable_transform="{{ as_ein }}",
             stable_format="12-3456789", examples="12-3456789 ;; 01-2345678")),
  mk(2, list(format_label="isbn",  data_format="{{ id:isbn }}", raw_to_stable_transform="{{ as_isbn }}",
             stable_format="9780140448061", examples="isbn 0062049879 ;; 978-0-14-044806-1 ;; 4-04-924701-1")),
  mk(3, list(format_label="doi",   data_format="{{ id:doi }}", raw_to_stable_transform="{{ as_doi }}",
             stable_format="10.1000/xyz123", examples="10.1000/xyz123 ;; doi:10.1038/nature12373")),
  mk(4, list(format_label="orcid", data_format="{{ id:orcid }}", raw_to_stable_transform="{{ as_orcid }}",
             stable_format="0000-0002-1825-0097", examples="0000-0002-1825-0097")),
  mk(5, list(format_label="issn",  data_format="{{ id:issn }}", raw_to_stable_transform="{{ as_issn }}",
             stable_format="2049-3630", examples="2049-3630 ;; 0028-0836")))
o <- rbind(o, do.call(rbind, rows))
o <- o[order(o$semantic_type_id, o$variant_id), ]
o$node_label <- .fx_derive_node_label(o)

prob <- fx_validate_ontology(o)
if (length(prob)) { cat("VALIDATION FAILED:\n"); cat(prob, sep="\n"); stop("aborted") }
utils::write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv); save(ontology, file = "data/ontology.rda", compress = "xz")
inst <- file.path(.libPaths()[1], "formex", "extdata", "research_data_type_ontology_v6.csv")
if (file.exists(dirname(inst))) file.copy(csv, inst, overwrite = TRUE)   # refresh installed copy
cat(sprintf("OK  %d rows now; administrative variants:\n", nrow(o)))
print(o[o$semantic_type_id=="n0073", c("variant_id","format_label","raw_to_stable_transform")], row.names=FALSE)
