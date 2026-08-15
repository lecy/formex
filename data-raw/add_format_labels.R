## data-raw/add_format_labels.R -------------------------------------------------
## Add the two governance axes the design settled on to the v6 ontology, then
## split the two families whose detectors already exist (or are queued) into one
## row per import recipe. Re-derives node_label, writes the CSV, rebuilds
## data/ontology.rda, and validates. Idempotent: safe to re-run.
##
##   format_label : the recipe's name, UNIQUE within a semantic_type_id
##   match_kind   : how build_detector() must construct the detector --
##                  genome | mask | lexicon | mask+lexicon | shape | none
##                  (this IS the "detector_type"; the function binding lives in
##                   the registry, and `implemented` already says "built?".)
##
## Row-as-recipe: a new row is minted only when a NEW recipe is needed (a format
## that needs its own detector, stable form, and import rule). Variants that one
## recipe already handles (currency symbol prefix OR suffix) stay one row.
## ---------------------------------------------------------------------------

source("R/14-fx-ontology.R")
csv <- "inst/extdata/research_data_type_ontology_v6.csv"
o   <- .fx_read_ontology_csv(csv)

## ---- 1. match_kind: the build-strategy axis, keyed on the type path ---------
mk_one <- function(dt, sf, st){
  if (dt == "temporal" && sf %in% c("date","time"))                 return("genome")
  if (dt == "temporal" && sf == "phase" &&
      st %in% c("day_of_week","month_of_year"))                     return("lexicon")
  if (dt == "temporal")                                             return("mask")   # period / interval
  if (dt == "text"     && sf == "name")                             return("lexicon")
  if (dt == "text"     && sf == "postal")                           return("mask+lexicon")
  if (dt == "text"     && sf %in% c("contact","web","color"))       return("mask")
  if (dt == "text")                                                 return("none")   # free text / label
  if (dt == "categorical" && st == "geographic")                    return("lexicon")
  if (dt == "categorical" && st == "classification_code")           return("mask+lexicon")
  if (dt == "categorical")                                          return("none")   # unordered/ordered/scale = metadata
  if (dt == "number"   && sf == "portion")                          return("shape")
  if (dt == "number"   && sf == "quantity")                         return("shape")
  if (dt == "number")                                               return("mask")   # coordinate / currency / range
  if (dt == "identifier" && st == "geographic")                     return("mask+lexicon")
  if (dt == "identifier")                                           return("mask")
  if (dt == "boolean")                                              return("mask")
  if (dt == "structured")                                           return("mask")
  "none"
}
o$match_kind <- mapply(mk_one, o$data_type, o$semantic_family, o$semantic_type)

## ---- 2. format_label: default = leaf name, disambiguated per id -------------
o$format_label <- o$semantic_type
for (id in unique(o$semantic_type_id[duplicated(o$semantic_type_id)])){
  i <- which(o$semantic_type_id == id)
  o$format_label[i] <- paste0(o$semantic_type[i], "_v", seq_along(i))
}
## nicer names for the two pre-existing multi-variant ids
lab <- function(vid, v){ o$format_label[o$variant_id == vid] <<- v }
lab("n0016-f01","comma_pair"); lab("n0016-f02","to_range")
lab("n0018-f01","dms");        lab("n0018-f02","iso6709")

## ---- 3. recipe splits (detectors exist / are queued) -----------------------
## helper: clone a base row, override named fields, mint variant_id f<vno>
recipe <- function(base, vno, fields){
  r <- base
  r$variant_id     <- sprintf("%s-f%02d", base$semantic_type_id, vno)
  r$version_added  <- if ("version_added" %in% names(r)) "v6" else r$version_added
  for (k in names(fields)) r[[k]] <- fields[[k]]
  r
}
drop_id <- function(o, id) o[o$semantic_type_id != id, , drop = FALSE]

## person  n0027 : one lexicon per name part + a structural full-name recipe
p <- o[o$semantic_type_id == "n0027", ][1, ]
o <- drop_id(o, "n0027")
o <- rbind(o,
  recipe(p,1,list(format_label="first_name", match_kind="lexicon",
    examples="James ;; Mary", data_format="{{ lexicon:given_name }}",
    raw_to_stable_transform="lookup:given", stable_format="given_name")),
  recipe(p,2,list(format_label="last_name", match_kind="lexicon",
    examples="Smith ;; Garcia", data_format="{{ lexicon:surname }}",
    raw_to_stable_transform="lookup:surname", stable_format="surname")),
  recipe(p,3,list(format_label="full_name", match_kind="mask+lexicon",
    examples="Jane Doe ;; Doe, Jane", data_format="{{ First Last ;; Last, First }}",
    raw_to_stable_transform="split+order", stable_format="first_last")))

## geographic  n0046 : one gazetteer per place vocabulary, plus masked FIPS
g <- o[o$semantic_type_id == "n0046", ][1, ]
o <- drop_id(o, "n0046")
o <- rbind(o,
  recipe(g,1,list(format_label="iso_country", match_kind="lexicon",
    examples="France ;; FR", data_format="{{ lexicon:iso3166 }}",
    raw_to_stable_transform="lookup:iso3166", stable_format="iso3166_alpha2")),
  recipe(g,2,list(format_label="us_state", match_kind="lexicon",
    examples="California ;; CA", data_format="{{ lexicon:usps_state }}",
    raw_to_stable_transform="lookup:usps", stable_format="usps_state")),
  recipe(g,3,list(format_label="us_city", match_kind="lexicon",
    examples="Chicago ;; Boston", data_format="{{ lexicon:us_city }}",
    raw_to_stable_transform="lookup:place", stable_format="place_name")),
  recipe(g,4,list(format_label="county_fips", match_kind="mask+lexicon",
    examples="06037 ;; 6037", data_format="{{ mask:fips5 + lexicon:fips }}",
    raw_to_stable_transform="zeropad5+validate", stable_format="fips5")))

## ---- 4. finalize: re-derive node_label, order columns, sort ----------------
o$node_label <- .fx_derive_node_label(o)
front <- c("semantic_type_id","variant_id","node_label","format_label","match_kind")
o <- o[, c(front, setdiff(names(o), front))]
o <- o[order(o$semantic_type_id, o$variant_id), ]

## ---- 5. validate BEFORE writing -------------------------------------------
prob <- fx_validate_ontology(o)
if (length(prob)) { cat("VALIDATION FAILED:\n"); cat(prob, sep="\n"); stop("aborted") }

utils::write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv)          # round-trip exactly what shipped
save(ontology, file = "data/ontology.rda", compress = "xz")

cat(sprintf("OK  %d rows, %d cols -> %s + data/ontology.rda\n",
            nrow(o), ncol(o), csv))
cat("\nmatch_kind distribution:\n"); print(table(o$match_kind))
cat("\nsplit families:\n")
print(o[o$semantic_type_id %in% c("n0027","n0046"),
        c("variant_id","format_label","match_kind","stable_format")], row.names=FALSE)
