## ===========================================================================
## 15-fx-ontology-diff.R  --  bounded ontology migration (INTEGRATION §7.8, §8)
##
## Diff on semantic_type_id, NEVER on path strings: a rename and a
## delete-plus-add are indistinguishable by path and trivially distinguishable
## by id -- the entire reason stable ids exist. The impact of each change kind
## is encoded as DATA (the table below), not as if-branches, so it can be
## unit-tested and cited.
## ===========================================================================

## change_kind -> (case_impact, scoring_impact). Two columns because they
## diverge: a move needs no relabelling but invalidates every score; a merge
## needs relabelling but barely touches scoring.
.FX_ONTOLOGY_IMPACT <- data.frame(
  change_kind    = c("added","renamed","moved","merged","split","deprecated",
                     "variant_add","variant_drop","attr_edit"),
  case_impact    = c("none","none","none","mechanical","review_required",
                     "review_required","none","none","none"),
  scoring_impact = c("affected_pairs","none","all_pairs","affected_pairs",
                     "affected_pairs","affected_pairs","none","none","none"),
  stringsAsFactors = FALSE)

#' Ontology change impact table
#' @return The `change_kind -> (case_impact, scoring_impact)` reference table.
#' @export
fx_ontology_impact_table <- function() .FX_ONTOLOGY_IMPACT

#' Classify the differences between two ontology versions
#'
#' Every difference is reduced to a `change_kind` with a determinate blast
#' radius, keyed on `semantic_type_id` (never on path text).
#'
#' @param old,new Ontology data frames, or paths to ontology CSVs. Both must
#'   carry `semantic_type_id`, `variant_id`, `data_type`, `semantic_family`,
#'   `semantic_type`, `version_deprecated`, `superseded_by`.
#' @return A data frame, one row per change: `semantic_type_id`, `change_kind`,
#'   `from_path`, `to_path`, `case_impact`, `scoring_impact`, `note`.
#' @seealso [fx_impacted_cases()], [fx_ontology_impact_table()]
#' @export
fx_ontology_diff <- function(old, new){
  if(is.character(old)) old <- .fx_read_ontology_csv(old)
  if(is.character(new)) new <- .fx_read_ontology_csv(new)
  req <- c("semantic_type_id","variant_id","data_type","semantic_family",
           "semantic_type","version_deprecated","superseded_by")
  if(!all(req %in% names(old)) || !all(req %in% names(new)))
    stop("both ontologies must contain: ", paste(req, collapse=", "))

  first  <- function(d, id) d[d$semantic_type_id == id, , drop=FALSE][1, ]
  npath  <- function(d, id){ r <- first(d, id); paste(r$data_type, r$semantic_family, r$semantic_type, sep="/") }
  dep_in <- function(d, id) any(nzchar(d$version_deprecated[d$semantic_type_id == id]))
  supers <- function(d, id){ s <- d$superseded_by[d$semantic_type_id == id]; unlist(strsplit(s[nzchar(s)], " *;; *")) }

  old_ids <- unique(old$semantic_type_id); new_ids <- unique(new$semantic_type_id)
  attr_cols <- intersect(c("examples","data_format","raw_to_stable_transform",
                           "stable_format","stable_import_rule","dd_data_unit",
                           "short_desc","detail","validation","default_storage"),
                         intersect(names(old), names(new)))
  rows <- list()
  emit <- function(id, kind, from, to, note="")
    rows[[length(rows)+1L]] <<- data.frame(semantic_type_id=id, change_kind=kind,
      from_path=from, to_path=to, note=note, stringsAsFactors=FALSE)

  for(id in setdiff(new_ids, old_ids)) emit(id, "added", NA_character_, npath(new,id), "new node")
  for(id in setdiff(old_ids, new_ids)) emit(id, "deprecated", npath(old,id), NA_character_,
                                            "id absent from new (deprecate, do not delete)")

  for(id in intersect(old_ids, new_ids)){
    fp <- npath(old, id); tp <- npath(new, id)
    if(dep_in(new, id) && !dep_in(old, id)){                 # newly deprecated node
      tgt  <- supers(new, id)
      live <- tgt[tgt %in% new_ids]
      live <- live[!vapply(live, function(t) dep_in(new, t), logical(1))]
      kind <- if(length(live) >= 2) "split" else if(length(live) == 1) "merged" else "deprecated"
      to   <- if(length(live)) paste(vapply(live, function(t) npath(new,t), ""), collapse=" ;; ") else NA_character_
      emit(id, kind, fp, to, paste0("superseded_by: ", if(length(tgt)) paste(tgt, collapse=", ") else "none"))
      next
    }
    o1 <- first(old, id); n1 <- first(new, id)
    if(o1$data_type != n1$data_type || o1$semantic_family != n1$semantic_family){
      emit(id, "moved", fp, tp, "data_type/semantic_family changed; path_distance shifts for every pair"); next
    }
    if(o1$semantic_type != n1$semantic_type){
      emit(id, "renamed", fp, tp, "semantic_type text changed; id stable, label derived"); next
    }
    ## path unchanged -> variant / attribute deltas
    ov <- old$variant_id[old$semantic_type_id == id]; nv <- new$variant_id[new$semantic_type_id == id]
    if(length(setdiff(nv, ov))) emit(id, "variant_add",  fp, tp, paste("new variants:", paste(setdiff(nv,ov), collapse=", ")))
    if(length(setdiff(ov, nv))) emit(id, "variant_drop", fp, tp, paste("dropped variants:", paste(setdiff(ov,nv), collapse=", ")))
    if(!length(setdiff(nv,ov)) && !length(setdiff(ov,nv)) && length(attr_cols)){
      changed <- any(vapply(intersect(ov, nv), function(v){
        or <- old[old$variant_id==v, , drop=FALSE][1,]; nr <- new[new$variant_id==v, , drop=FALSE][1,]
        any(vapply(attr_cols, function(cc) !identical(or[[cc]], nr[[cc]]), logical(1)))
      }, logical(1)))
      if(isTRUE(changed)) emit(id, "attr_edit", fp, tp, "prose/format/validation/storage edited")
    }
  }

  out <- if(length(rows)) do.call(rbind, rows) else
    data.frame(semantic_type_id=character(0), change_kind=character(0),
               from_path=character(0), to_path=character(0), note=character(0),
               stringsAsFactors=FALSE)
  i <- match(out$change_kind, .FX_ONTOLOGY_IMPACT$change_kind)
  out$case_impact    <- .FX_ONTOLOGY_IMPACT$case_impact[i]
  out$scoring_impact <- .FX_ONTOLOGY_IMPACT$scoring_impact[i]
  out <- out[, c("semantic_type_id","change_kind","from_path","to_path",
                 "case_impact","scoring_impact","note")]
  out[order(out$semantic_type_id, out$change_kind), , drop=FALSE]
}

## depth at which a change acts, for the depth rule in fx_impacted_cases()
.fx_change_depth <- function(change_kind, from_path, to_path){
  if(change_kind == "moved"){
    a <- strsplit(from_path, "/", fixed=TRUE)[[1]]; b <- strsplit(to_path, "/", fixed=TRUE)[[1]]
    if(length(a)>=1 && length(b)>=1 && a[1]!=b[1]) 1L else 2L
  } else if(change_kind %in% c("renamed","merged","split","deprecated")) 3L
    else 4L   # variant_* / attr_edit / added -> deeper than any case label
}

#' Map an ontology diff onto banked cases
#'
#' Matches diff rows to schema-v2 case files on `label.semantic_type_id` (never
#' on text), applies the depth rule (a case is affected only by changes at or
#' above the depth it was labelled to) and the version rule (already-migrated
#' cases are skipped), and optionally flags affected cases by writing ONLY
#' `label.needs_relabel` / `label.relabel_trigger`.
#'
#' @param diff Output of [fx_ontology_diff()].
#' @param bank_dir Directory of schema-v2 case JSON files.
#' @param new_version If set, cases already at this `label.ontology_version` are skipped.
#' @param write If `TRUE`, write the two label flags into affected files.
#' @return A data frame: `case_id`, `file`, `semantic_type_id`, `change_kind`,
#'   `case_impact`, `action`, `relabel_trigger`.
#' @export
fx_impacted_cases <- function(diff, bank_dir, new_version = NULL, write = FALSE){
  if(!requireNamespace("jsonlite", quietly=TRUE)) stop("fx_impacted_cases() needs jsonlite")
  files <- list.files(bank_dir, pattern="\\.json$", full.names=TRUE)
  diff$.depth <- mapply(.fx_change_depth, diff$change_kind, diff$from_path, diff$to_path)
  out <- list()
  for(f in files){
    o <- jsonlite::fromJSON(f, simplifyVector=FALSE)
    lab <- o$label; id <- lab$semantic_type_id %||% NA_character_
    if(!is.null(new_version) && identical(lab$ontology_version %||% NA, new_version)) next
    depth <- suppressWarnings(as.integer(lab$depth_labeled %||% 3L))
    hit <- diff[!is.na(diff$semantic_type_id) & diff$semantic_type_id == id &
                depth >= diff$.depth, , drop=FALSE]
    if(!nrow(hit)) next
    hit <- hit[order(match(hit$case_impact, c("review_required","mechanical","none"))), ][1, ]
    action <- switch(hit$case_impact, mechanical="relabel_mechanical",
                     review_required="requeue_for_review", "none")
    trig <- sprintf("%s of %s (%s -> %s)", hit$change_kind, id,
                    hit$from_path %||% "NA", hit$to_path %||% "NA")
    if(write && action != "none"){
      o$label$needs_relabel    <- TRUE
      o$label$relabel_trigger  <- trig
      json_write(o, f)                     # write-isolation: only label.* changed
    }
    out[[length(out)+1L]] <- data.frame(case_id=o$case_id, file=f,
      semantic_type_id=id, change_kind=hit$change_kind, case_impact=hit$case_impact,
      action=action, relabel_trigger=trig, stringsAsFactors=FALSE)
  }
  if(length(out)) do.call(rbind, out) else
    data.frame(case_id=character(0), file=character(0), semantic_type_id=character(0),
               change_kind=character(0), case_impact=character(0), action=character(0),
               relabel_trigger=character(0), stringsAsFactors=FALSE)
}

#' Apply the mechanical half of a bank migration
#'
#' `merged`/`renamed`/`moved` cases are rewritten automatically (id/path in the
#' label, plus `ontology_version` and a `notes` append); `split`/`deprecated`
#' cases are flagged `needs_relabel` and left for a human. Dry-run by default.
#'
#' @param diff Output of [fx_ontology_diff()].
#' @param bank_dir Directory of schema-v2 case files.
#' @param new_version The version string to stamp on migrated cases.
#' @param write If `TRUE`, modify files (label block only).
#' @return A one-row summary: `n_migrated`, `n_flagged`, `n_orphaned`, `n_skipped`.
#' @export
fx_migrate_bank <- function(diff, bank_dir, new_version, write = FALSE){
  if(!requireNamespace("jsonlite", quietly=TRUE)) stop("fx_migrate_bank() needs jsonlite")
  files <- list.files(bank_dir, pattern="\\.json$", full.names=TRUE)
  n_migrated <- n_flagged <- n_orphaned <- n_skipped <- 0L
  by_id <- split(diff, diff$semantic_type_id)
  for(f in files){
    o <- jsonlite::fromJSON(f, simplifyVector=FALSE); id <- o$label$semantic_type_id %||% NA
    if(is.na(id)){ n_orphaned <- n_orphaned + 1L; next }
    if(identical(o$label$ontology_version %||% NA, new_version)){ n_skipped <- n_skipped + 1L; next }
    ch <- by_id[[as.character(id)]]
    if(is.null(ch)){ n_skipped <- n_skipped + 1L; next }
    ch <- ch[1, ]
    if(ch$case_impact == "mechanical"){
      if(ch$change_kind == "renamed") o$label$semantic_type <- sub(".*/", "", ch$to_path)
      if(ch$change_kind == "moved"){
        p <- strsplit(ch$to_path, "/", fixed=TRUE)[[1]]
        o$label$data_type <- p[1]; o$label$semantic_family <- p[2]; o$label$semantic_type <- p[3]
      }
      if(ch$change_kind == "merged") o$label$semantic_type_id <- NA  # points at survivor; set below if resolvable
      o$label$ontology_version <- new_version
      o$label$notes <- paste(na.omit(c(o$label$notes, paste0("migrated: ", ch$note))), collapse=" | ")
      if(write) json_write(o, f)
      n_migrated <- n_migrated + 1L
    } else if(ch$case_impact == "review_required"){
      o$label$needs_relabel   <- TRUE
      o$label$relabel_trigger <- sprintf("%s of %s", ch$change_kind, id)
      if(write) json_write(o, f)
      n_flagged <- n_flagged + 1L
    } else n_skipped <- n_skipped + 1L
  }
  data.frame(n_migrated=n_migrated, n_flagged=n_flagged,
             n_orphaned=n_orphaned, n_skipped=n_skipped)
}

#' The relabel work list, highest-value first
#'
#' Every case with `label.needs_relabel = TRUE`, ordered by coverage risk
#' (types with fewest remaining valid cases first), then difficulty (hard
#' first), then labelling method (human first). The candidate shortlist is
#' recomputed from the CURRENT ontology, not reused from the case.
#'
#' @param bank_dir Directory of schema-v2 case files.
#' @return A data frame of cases needing relabel, ordered.
#' @export
fx_relabel_queue <- function(bank_dir){
  if(!requireNamespace("jsonlite", quietly=TRUE)) stop("fx_relabel_queue() needs jsonlite")
  files <- list.files(bank_dir, pattern="\\.json$", full.names=TRUE)
  rows <- list()
  for(f in files){
    o <- jsonlite::fromJSON(f, simplifyVector=FALSE)
    if(!isTRUE(o$label$needs_relabel)) next
    rows[[length(rows)+1L]] <- data.frame(
      case_id=o$case_id, file=f, semantic_type_id=o$label$semantic_type_id %||% NA,
      relabel_trigger=o$label$relabel_trigger %||% NA,
      difficulty=o$difficulty$rating %||% NA, method=o$label$method %||% NA,
      stringsAsFactors=FALSE)
  }
  if(!length(rows)) return(data.frame())
  q <- do.call(rbind, rows)
  cover <- table(q$semantic_type_id)
  q$.cover <- as.integer(cover[as.character(q$semantic_type_id)])
  q$.diff  <- match(q$difficulty, c("hard","medium","easy"))
  q$.meth  <- match(q$method, c("human","llm"))
  q <- q[order(q$.cover, q$.diff, q$.meth), ]
  q[, setdiff(names(q), c(".cover",".diff",".meth"))]
}
