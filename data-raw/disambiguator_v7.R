## data-raw/disambiguator_v7.R -------------------------------------------------
## Disambiguate the ontology's path collisions (datagoodr devnote S5). Two labels
## map to more than one path:
##   geographic  -> categorical/.../geographic  AND  identifier/id/geographic
##   mixed       -> boolean/binary/mixed         AND  unknown/unknown/mixed
##
## Fixes:
##   1. add a `disambiguator` column (the declared tie-break rule).
##   2. geographic: a grouping repeats across rows; a key is unique per row --
##      declare cardinality so the verifier can pick (and so a leaf-only
##      consumer has a defined rule).
##   3. mixed: rename unknown/unknown/mixed -> unknown/unknown/heterogeneous,
##      removing the collision outright (the boolean "mixed" keeps its name).
##
## fx_validate_ontology() now FAILS on an undeclared collision, so this must run
## before the ontology validates. Re-derives node_label, rebuilds the rda.
## Run: Rscript data-raw/disambiguator_v7.R    (idempotent)
## ---------------------------------------------------------------------------
source("R/14-fx-ontology.R")
csv <- "inst/extdata/research_data_type_ontology_v7.csv"
o   <- .fx_read_ontology_csv(csv)

## 1. disambiguator column
if(!"disambiguator" %in% names(o)) o$disambiguator <- ""

## 2. geographic: categorical grouping vs identifier key, split on cardinality
o$disambiguator[o$semantic_type == "geographic" & o$data_type == "categorical"] <- "cardinality:repeating"
o$disambiguator[o$semantic_type == "geographic" & o$data_type == "identifier"]  <- "cardinality:unique"

## 2b. make BOTH geographic paths confirm via FIPS validation, so the tie-break
## actually fires (county_fips categorical, and id/geographic). as_fips rejects
## a random 5-digit number, so geographic now outranks a bare count.
o$raw_to_stable_transform[o$variant_id %in% c("n0046-f04", "n0074-f01")] <- "{{ as_fips }}"

## 2c. a cross-TYPE collision: a column of city names is validly a place NAME
## (text/name/place) or a geographic GROUPING (categorical/.../us_city) -- same
## lookup:place recipe, so both confirm. They share no label, so declare them a
## collision_group and resolve by cardinality (repeating -> grouping, unique ->
## names), reusing the same rule as the geographic/identifier split.
if(!"collision_group" %in% names(o)) o$collision_group <- ""
o$collision_group[o$variant_id %in% c("n0029-f01", "n0046-f03")] <- "geo_place"
o$disambiguator[o$variant_id == "n0029-f01"] <- "cardinality:unique"      # place names
## n0046-f03 (us_city) already carries cardinality:repeating from the geographic rule

## 3. rename the unknown "mixed" leaf to heterogeneous (kills the collision)
het <- o$variant_id == "n0083-f01"
o$semantic_type[het] <- "heterogeneous"
o$format_label[het]  <- "heterogeneous"
if("format_style" %in% names(o)) o$format_style[het] <- "heterogeneous"
o$short_desc[het]    <- "A column mixing several data types."

## reposition disambiguator after unit_type (beside the leaf axes)
move_after <- function(df, move, anchor){
  keep <- setdiff(names(df), move); i <- match(anchor, keep); df[, append(keep, move, after = i)] }
anchor <- if("unit_type" %in% names(o)) "unit_type" else "format_label"
o <- move_after(o, "disambiguator", anchor)
o <- move_after(o, "collision_group", "disambiguator")

## re-derive node_label, validate (guard now active), persist
o$node_label <- .fx_derive_node_label(o)
probs <- fx_validate_ontology(o)
if(length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse = "\n  "))

write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv)
if(!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2)
cat(sprintf("disambiguator set on %d rows; 'mixed' collision removed; validation CLEAN\n",
            sum(nzchar(o$disambiguator))))
