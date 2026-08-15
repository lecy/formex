## ===========================================================================
## 14-fx-ontology.R  --  load and integrity-check the research data-type
## ontology (v6). The ontology ships twice on purpose (INTEGRATION §3):
##   * inst/extdata/research_data_type_ontology_v6.csv  -- human-readable/diffable
##   * data/ontology.rda                                -- parsed, lazy-loaded
## fx_ontology() is the accessor; a test asserts the two agree.
##
## HARD CONSTRAINTS (INTEGRATION §4): load-bearing columns are never renamed;
## node ids are allocated, never renumbered; rows are deprecated, never deleted;
## node_label is DERIVED and never a key.
## ===========================================================================

## ---- three-letter mnemonics (must match inst/scripts/mint_node_ids.R) ------
.FX_TYPE_ABB <- c(number="NUM", categorical="CAT", temporal="TMP", boolean="BOO",
                  text="TXT", identifier="IDN", structured="CPX", unknown="UNK")
.FX_CLASS_ABB <- c(id = "KEY")

## family abbreviation with the SAME deterministic collision resolution the
## minting script used (e.g. color -> COR because collection already holds COL).
.fx_abbrev3 <- function(x){
  a <- toupper(substr(gsub("[^A-Za-z]", "", x), 1, 3))
  hit <- x %in% names(.FX_CLASS_ABB); a[hit] <- unname(.FX_CLASS_ABB[x[hit]])
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

## re-derive node_label from the identity columns, for the integrity check
.fx_derive_node_label <- function(ont){
  vno <- as.integer(sub(".*-f", "", ont$variant_id))
  sprintf("%s-%s-%s-f%02d", unname(.FX_TYPE_ABB[ont$data_type]),
          .fx_abbrev3(ont$semantic_family), ont$semantic_type_id, vno)
}

## canonical reader: everything character, empties kept as "" (not NA), so the
## CSV round-trips exactly and version_deprecated == "" means "live".
#' @keywords internal
#' @noRd
.fx_read_ontology_csv <- function(path){
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                  colClasses = "character", na.strings = character(0))
}

#' The research data-type ontology (v6)
#'
#' @return A data frame of ontology rows (one per format variant), with the
#'   load-bearing identity columns `semantic_type_id`, `variant_id`,
#'   `node_label`, the path columns `data_type` / `semantic_family` /
#'   `semantic_type`, and lifecycle columns (`version_added`,
#'   `version_deprecated`, `superseded_by`).
#' @seealso [fx_validate_ontology()]
#' @export
fx_ontology <- function(){
  p <- system.file("extdata", "research_data_type_ontology_v6.csv", package = "formex")
  if(!nzchar(p) || !file.exists(p)){                       # dev / test fallback
    for(cand in c("inst/extdata/research_data_type_ontology_v6.csv",
                  "../../inst/extdata/research_data_type_ontology_v6.csv",
                  "../../../inst/extdata/research_data_type_ontology_v6.csv"))
      if(file.exists(cand)){ p <- cand; break }
  }
  .fx_read_ontology_csv(p)
}

#' Integrity-check an ontology table
#'
#' Enforces the invariants that keep banked cases valid across versions
#' (INTEGRATION §4). Meant to run in `R CMD check`.
#'
#' @param ont An ontology data frame (defaults to [fx_ontology()]).
#' @return A character vector of problems; empty (`character(0)`) when valid.
#' @seealso [fx_ontology()]
#' @export
fx_validate_ontology <- function(ont = fx_ontology()){
  p <- character(0)
  path <- paste(ont$data_type, ont$semantic_family, ont$semantic_type, sep = "/")

  ## 1. variant_id unique across all rows
  if(any(duplicated(ont$variant_id)))
    p <- c(p, paste("duplicate variant_id:",
                    paste(unique(ont$variant_id[duplicated(ont$variant_id)]), collapse=", ")))

  ## 2. semantic_type_id <-> path is a bijection (id per path, path per id)
  id_per_path <- tapply(ont$semantic_type_id, path, function(z) length(unique(z)))
  if(any(id_per_path > 1))
    p <- c(p, paste("path with >1 semantic_type_id:",
                    paste(names(id_per_path)[id_per_path>1], collapse=", ")))
  path_per_id <- tapply(path, ont$semantic_type_id, function(z) length(unique(z)))
  if(any(path_per_id > 1))
    p <- c(p, paste("semantic_type_id reused across paths:",
                    paste(names(path_per_id)[path_per_id>1], collapse=", ")))

  ## 3. node_label matches the derivation rule exactly
  bad <- which(ont$node_label != .fx_derive_node_label(ont))
  if(length(bad))
    p <- c(p, paste("node_label mismatch at rows:", paste(head(bad,10), collapse=", ")))

  ## 4. no id reused after deprecation: an id that is deprecated for one path
  ##    must not reappear live under a different path (subsumed by #2, checked
  ##    explicitly so a cross-version reuse is named, not just implied)
  dep_ids <- unique(ont$semantic_type_id[nzchar(ont$version_deprecated)])
  reused  <- dep_ids[vapply(dep_ids, function(id)
               length(unique(path[ont$semantic_type_id == id])) > 1, logical(1))]
  if(length(reused))
    p <- c(p, paste("deprecated id reused for a new path:", paste(reused, collapse=", ")))

  ## 5. every superseded_by target exists as a semantic_type_id
  tgt <- unlist(strsplit(ont$superseded_by[nzchar(ont$superseded_by)], " *;; *"))
  miss <- setdiff(tgt, ont$semantic_type_id)
  if(length(miss))
    p <- c(p, paste("superseded_by targets not found:", paste(miss, collapse=", ")))

  ## 6. format_label present, and unique within a semantic_type_id (each recipe
  ##    named once); match_kind drawn from the controlled set
  if("format_label" %in% names(ont)){
    if(any(!nzchar(ont$format_label)))
      p <- c(p, "empty format_label")
    dup <- tapply(ont$format_label, ont$semantic_type_id, function(z) any(duplicated(z)))
    if(any(dup))
      p <- c(p, paste("duplicate format_label within:", paste(names(dup)[dup], collapse=", ")))
  }
  if("match_kind" %in% names(ont)){
    bad <- setdiff(unique(ont$match_kind), c("genome","mask","lexicon","mask+lexicon","shape","none"))
    if(length(bad)) p <- c(p, paste("unknown match_kind:", paste(bad, collapse=", ")))
  }

  p
}

#' Research data-type ontology (v6), parsed
#'
#' The lazy-loaded copy of `inst/extdata/research_data_type_ontology_v6.csv`.
#' Identical to [fx_ontology()]; provided for direct `formex::ontology` access.
#'
#' @format A data frame with one row per import recipe (`format_label`), keyed by
#'   `semantic_type_id` + `variant_id`; `match_kind` names the detector-build
#'   strategy (genome/mask/lexicon/mask+lexicon/shape/none).
#' @source `inst/extdata/research_data_type_ontology_v6.csv`
"ontology"
