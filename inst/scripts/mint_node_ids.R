## ===========================================================================
## mint_node_ids.R -- add stable identity + versioning columns to the ontology
##
## Design decision (see notes): the KEY is immutable and meaningless; the
## READABLE label is derived and regenerable. They are separate columns.
## Case files store the key. Humans read the label.
##
##   semantic_type_id  n0042      immutable. The SCORING unit. Cases reference
##                                this and only this.
##   variant_id    n0042-f01      immutable. The ROW unit. Detectors,
##                                transforms and import rules reference this.
##                                "f" = format expression, and deliberately
##                                NOT "v", which reads as semantic versioning.
##   node_label    NUM-COO-n0042-f01   DERIVED, display only. Never stored as
##                                a foreign key, never diffed for identity.
##
## Counters are ALLOCATED, not counted: they increase monotonically and are
## never reused, so a deprecated n0042 leaves a permanent hole. Densely
## renumbering after a deletion would silently repoint every case that
## referenced the old node.
## ===========================================================================

IN  <- "/mnt/user-data/uploads/research_data_type_ontology_v4.csv"

## Column rename applied on the way through (schema change, not a node change,
## so version_added stays at v4):
##   data_class    -> semantic_family
##   data_subclass -> semantic_type      <- the unit of analysis
##   subclass_id   -> semantic_type_id
## data_type is KEPT: it names a modality (what operations are admissible),
## not a storage mode.
OUT <- "/mnt/user-data/outputs/research_data_type_ontology_v6.csv"
THIS_VERSION <- "v6"

d <- read.csv(IN, stringsAsFactors = FALSE, check.names = FALSE)

## GUARD: this is a one-off migration that already ran. Re-minting from an
## already-minted ontology would reallocate ids from scratch and silently
## repoint every banked case. Refuse if identity columns already exist.
if("semantic_type_id" %in% names(d))
  stop("Input already has semantic_type_id -- refusing to re-mint. ",
       "Node ids are allocated once and never renumbered (INTEGRATION §4).")

names(d)[names(d) == "data_class"]    <- "semantic_family"
names(d)[names(d) == "data_subclass"] <- "semantic_type"
names(d)[names(d) == "data_format_default_class"] <- "data_format_default_family"

## ---- three-letter mnemonics ------------------------------------------------
## Hand-set for data_type: mechanical truncation would give "STR" for both
## structured and (potentially) string/text, which is exactly the kind of
## ambiguity a display label should not have.

TYPE_ABB <- c(
  number      = "NUM",
  categorical = "CAT",
  temporal    = "TMP",
  boolean     = "BOO",
  text        = "TXT",
  identifier  = "IDN",
  structured  = "CPX",   # not STR -- avoids colliding with "string"
  unknown     = "UNK"
)

## a few classes need explicit mnemonics: "id" truncates to two characters,
## which makes label widths ragged and sorts oddly
CLASS_ABB <- c(id = "KEY")

abbrev3 <- function(x){
  a <- toupper(substr(gsub("[^A-Za-z]", "", x), 1, 3))
  hit <- x %in% names(CLASS_ABB); a[hit] <- unname(CLASS_ABB[x[hit]])
  ## resolve collisions deterministically by extending, then by suffixing
  dup <- unique(a[duplicated(a)])
  for(k in dup){
    hit <- which(a == k); src <- unique(x[hit])
    if(length(src) > 1){
      for(i in seq_along(src)){
        alt <- toupper(paste0(substr(src[i],1,2), substr(src[i], nchar(src[i]), nchar(src[i]))))
        if(!(alt %in% a) || alt == k) a[x == src[i]] <- alt
      }
    }
  }
  a
}

stopifnot(all(d$data_type %in% names(TYPE_ABB)))
type_ab  <- unname(TYPE_ABB[d$data_type])
fam_ab <- abbrev3(d$semantic_family)

## ---- allocate semantic_type ids in stable file order ----------------------------

path <- paste(d$data_type, d$semantic_family, d$semantic_type, sep = "/")
uniq <- unique(path)
semantic_type_id <- setNames(sprintf("n%04d", seq_along(uniq)), uniq)
d$semantic_type_id <- unname(semantic_type_id[path])

## ---- allocate variant numbers within semantic_type ------------------------------
## Monotonic within semantic_type, never reused. v01 is not "the first row now" but
## "the first variant ever minted for this semantic_type".

d$variant_no <- ave(seq_len(nrow(d)), d$semantic_type_id, FUN = seq_along)
d$variant_id <- sprintf("%s-f%02d", d$semantic_type_id, d$variant_no)

## ---- derived display label -------------------------------------------------

d$node_label <- sprintf("%s-%s-%s-f%02d", type_ab, fam_ab, d$semantic_type_id, d$variant_no)

## ---- versioning / lifecycle columns ---------------------------------------
## Rows are never deleted. Deprecation is a state, so the impact function can
## always resolve a stale reference instead of failing on a missing key.

d$version_added       <- "v4"   # every current row existed as of v4
d$version_deprecated  <- ""     # set instead of deleting a row
d$superseded_by       <- ""     # subclass_id(s), ";;"-separated for splits
d$change_note         <- ""     # free text, what changed and why

## ---- column order: identity first ------------------------------------------

id_cols  <- c("semantic_type_id","variant_id","node_label","version_added",
              "version_deprecated","superseded_by","change_note")
d <- d[, c(id_cols, setdiff(names(d), c(id_cols, "variant_no")))]

dir.create("/mnt/user-data/outputs", showWarnings = FALSE, recursive = TRUE)
write.csv(d, OUT, row.names = FALSE, na = "")

cat("wrote", OUT, "\n")
cat("rows:", nrow(d), " distinct semantic_type_ids:", length(unique(d$semantic_type_id)),
    " multi-variant semantic types:", sum(table(d$semantic_type_id) > 1), "\n\n")
print(head(d[, c("semantic_type_id","variant_id","node_label","data_type",
                 "semantic_family","semantic_type")], 6), row.names = FALSE)
cat("\nthe two existing multi-variant semantic types:\n")
mv <- names(which(table(d$semantic_type_id) > 1))
print(d[d$semantic_type_id %in% mv, c("variant_id","node_label","semantic_type","examples")],
      row.names = FALSE)
