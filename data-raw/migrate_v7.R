## data-raw/migrate_v7.R --------------------------------------------------------
## v7 schema step: split the single leaf axis into TWO orthogonal axes and give
## the stabilizer an explicit output-format default. Additive and non-breaking:
## `format_label` is kept (derived) for one release, so the router/verifier and
## fx_stabilize() keep working unchanged while consumers migrate.
##
##   format_style            the WRITTEN rendering (order+separators, suffixes,
##                           abbreviated-vs-full) -- what read_*/write_* key on.
##                           Seeded from format_label; diverges as styles are
##                           named per family.
##   unit_type               RENAMED from dd_data_unit, moved next to the style
##                           axis. The dimensional/categorical unit that carries
##                           meaning and may need a convert_* (USD, C/F, fiscal).
##   desired_default_format  the write_* target to pre-fill when the human
##                           expresses no preference (e.g. yyyymmdd for calendar).
##
## Re-derives node_label, writes the CSV, rebuilds data/ontology.rda, validates.
## Idempotent: safe to re-run.  Run: Rscript data-raw/migrate_v7.R
## ---------------------------------------------------------------------------
source("R/14-fx-ontology.R")
csv <- "inst/extdata/research_data_type_ontology_v7.csv"
o   <- .fx_read_ontology_csv(csv)

## ---- 1. rename dd_data_unit -> unit_type ----------------------------------
if ("dd_data_unit" %in% names(o) && !"unit_type" %in% names(o))
  names(o)[names(o) == "dd_data_unit"] <- "unit_type"

## ---- 2. format_style: the written-rendering axis --------------------------
## Seed from format_label (which already carries style names for the multi-
## variant families: comma_pair/to_range, dms/iso6709). Equal to format_label
## today; the detector will refine it per family in a later step.
if (!"format_style" %in% names(o)) o$format_style <- o$format_label

## ---- 3. desired_default_format: the write_* target default ----------------
## Seed the families whose canonical output is unambiguous; blank elsewhere
## (blank = "no preference -> emit the canonical/ISO form").
if (!"desired_default_format" %in% names(o)) o$desired_default_format <- ""
def_by_type <- function(dt, sf, st){
  key <- paste(dt, sf, st, sep = "/")
  switch(key,
    "temporal/date/calendar"       = "yyyymmdd",
    "temporal/date/timestamp"      = "yyyymmddThhmmss",
    "temporal/time/clock"          = "hhmmss24",
    "temporal/period/year"         = "yyyy",
    "temporal/period/quarter"      = "yyyyQq",
    "temporal/period/month"        = "yyyymm",
    "")
}
blank <- !nzchar(o$desired_default_format)
o$desired_default_format[blank] <-
  mapply(def_by_type, o$data_type[blank], o$semantic_family[blank], o$semantic_type[blank])
## numeric families emit a plain number by default
o$desired_default_format[o$data_type == "number" & !nzchar(o$desired_default_format)] <- "numeric"

## ---- 4. reposition: format_style after format_label, unit_type after it,
##          desired_default_format after stable_import_rule -------------------
move_after <- function(df, move, anchor){
  keep <- setdiff(names(df), move)
  i    <- match(anchor, keep)
  df[, append(keep, move, after = i)]
}
o <- move_after(o, "format_style",           "format_label")
o <- move_after(o, "unit_type",              "format_style")
o <- move_after(o, "desired_default_format", "stable_import_rule")

## ---- 5. re-derive node_label, validate, persist ---------------------------
o$node_label <- .fx_derive_node_label(o)
probs <- fx_validate_ontology(o)
if (length(probs)) stop("ontology integrity failures:\n  ", paste(probs, collapse = "\n  "))

write.csv(o, csv, row.names = FALSE, na = "")
ontology <- .fx_read_ontology_csv(csv)
if (!dir.exists("data")) dir.create("data")
save(ontology, file = "data/ontology.rda", version = 2)

cat(sprintf("v7 migration OK: %d rows, %d cols\n  new/renamed cols: %s\n",
            nrow(o), ncol(o),
            paste(intersect(c("format_style","unit_type","desired_default_format"), names(o)), collapse = ", ")))
cat("  column order near the leaf axis:\n    ",
    paste(names(o)[match("semantic_type",names(o)):match("desired_default_format",names(o))], collapse=" | "), "\n")
