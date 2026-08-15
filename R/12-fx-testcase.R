## ===========================================================================
## fx_make_test_case.R  --  banks one column as a schema-v2 test case JSON file
##
## v2 changes:
##   - Label block is ONTOLOGY-ALIGNED: data_type / semantic_family /
##     semantic_type / semantic_type_id / ontology_version, replacing the old
##     free-text precise/generic pair.
##   - depth_labeled records how deep the label goes. A case labelled only to
##     data_type is a valid case, not a failed one -- graceful failure applies
##     to the bank as well as to the detector.
##   - candidates[] stores the signature-derived shortlist shown to the
##     labeller, so the decision is reproducible and its errors auditable.
##   - hard_negative_for[] carries CASE-LEVEL confusability exceptions only.
##     Type-level confusability lives in the ontology sidecar.
##   - needs_relabel / relabel_trigger are written by ontology_diff() only.
##   - FIELD ORDER: label, difficulty, provenance and preview at the top; raw
##     values and derived features below. Scannable without scrolling.
##
## WRITE ISOLATION -- each pass touches only its own blocks:
##   pass 1  fx_make_test_case()  writes everything EXCEPT label.*
##   pass 2  LLM labelling     writes ONLY label.*
##   pass 3  human review      writes ONLY label.method / reviewer / overrides
##   pass 4  mutation harness  creates NEW files, never edits existing ones
## This is what makes relabelling after an ontology change cheap: pass 2 is
## re-run alone, and the expensive-to-resource raw values are never at risk.
##
## Requires: extract_features2.R, type_similarity.R
## ===========================================================================

SCHEMA_VERSION <- "2.0"

`%||%` <- function(a, b) if(is.null(a) || length(a) == 0) b else a

## ---- minimal dependency-free JSON writer --------------------------------

.arr <- function(x){ class(x) <- c("json_array", class(x)); x }

.esc <- function(s){
  s <- gsub( "\\", "\\\\", s, fixed = TRUE )
  s <- gsub( "\"", "\\\"",  s, fixed = TRUE )
  s <- gsub( "\n", "\\n",   s, fixed = TRUE )
  s <- gsub( "\r", "\\r",   s, fixed = TRUE )
  s <- gsub( "\t", "\\t",   s, fixed = TRUE )
  gsub( "[\001-\037]", "", s )
}

.scalar <- function(x){
  if( is.null(x) || (length(x) == 1 && is.na(x)) ) return("null")
  if( is.logical(x) )   return( if(x) "true" else "false" )
  if( is.numeric(x) ){
    if( !is.finite(x) ) return("null")
    return( format(x, digits = 10, scientific = FALSE, trim = TRUE) )
  }
  paste0( "\"", .esc(as.character(x)), "\"" )
}

.to_json <- function( x, indent = 0 ){
  pad  <- strrep("  ", indent)
  pad2 <- strrep("  ", indent + 1)

  if( is.null(x) ) return("null")

  if( is.list(x) && !is.null(names(x)) && !inherits(x, "json_array") ){
    if( !length(x) ) return("{}")
    body <- vapply( seq_along(x), function(i)
              paste0( pad2, "\"", .esc(names(x)[i]), "\": ",
                      .to_json(x[[i]], indent + 1) ), character(1) )
    return( paste0("{\n", paste(body, collapse = ",\n"), "\n", pad, "}") )
  }

  if( is.list(x) || inherits(x, "json_array") ){
    if( !length(x) ) return("[]")
    elems <- lapply( x, function(e)
               if( is.list(e) || inherits(e,"json_array") ) .to_json(e, indent+1)
               else .scalar(e) )
    ## keep short flat arrays on one line for readability
    flat <- !any( grepl("\n", unlist(elems)) )
    if( flat && sum(nchar(unlist(elems))) < 70 )
      return( paste0("[", paste(unlist(elems), collapse=", "), "]") )
    return( paste0("[\n", paste0(pad2, unlist(elems), collapse = ",\n"),
                   "\n", pad, "]") )
  }

  if( length(x) == 1 ) return( .scalar(x) )
  .to_json( .arr(as.list(x)), indent )
}

json_write <- function( obj, path ){
  txt <- if( requireNamespace("jsonlite", quietly = TRUE) )
           jsonlite::toJSON( obj, auto_unbox = TRUE, pretty = TRUE,
                             na = "null", digits = 10 )
         else .to_json( obj )
  writeLines( as.character(txt), path, useBytes = TRUE )
  invisible( path )
}

## ---- compact triage profile ---------------------------------------------

profile_vector <- function( x ){

  n  <- length(x)
  xs <- as.character( x[ !is.na(x) ] )
  sentinel <- c("", " ", ".", "-", "n/a", "na", "null", "none", "nan",
                "unknown", "unk", "missing", "?")
  n_sent <- sum( tolower(trimws(xs)) %in% sentinel )
  xv <- xs[ !(tolower(trimws(xs)) %in% sentinel) ]

  if( !length(xv) ) return( list( n = n, n_missing = n, pct_missing = 1 ) )

  tb <- sort( table(xv), decreasing = TRUE )
  u  <- names(tb); cnt <- as.integer(tb); nu <- length(u); N <- length(xv)

  p <- cnt / N
  H <- -sum( p * log(p) )
  L <- nchar( u )
  Lw <- rep( L, cnt )                      # frequency-weighted lengths

  has_d <- grepl("[0-9]", u); has_a <- grepl("[A-Za-z]", u)
  has_p <- grepl("[^0-9A-Za-z ]", u)
  charset <-
    if( all(grepl("^[0-9]+$", u)) )                       "all_numeric"
    else if( all(grepl("^[A-Za-z ]+$", u)) )              "all_alpha"
    else if( all(has_d & has_a) && !any(has_p) )          "alphanumeric"
    else if( all(has_a) && !any(has_d) )                  "alpha_punct"
    else if( all(has_d) && !any(has_a) )                  "numeric_punct"
    else                                                  "mixed"

  ## punctuation: presence, count constancy, positional constancy
  punct_chars <- unique( unlist( strsplit( gsub("[0-9A-Za-z ]", "", u), NULL ) ) )
  punct <- lapply( punct_chars, function(ch){
    esc <- gsub("([][^$.|?*+(){}\\\\])", "\\\\\\1", ch)
    ct  <- nchar(u) - nchar(gsub(esc, "", u))
    pos <- regexpr(esc, u); pos[pos < 0] <- NA
    present <- ct > 0
    list( char              = ch,
          present_rate      = round( sum(cnt[present]) / N, 4 ),
          count_is_constant = length(unique(ct[present])) == 1,
          modal_position    = if( all(is.na(pos)) ) NA_integer_
                              else as.integer(names(sort(table(pos), decreasing=TRUE))[1]),
          position_is_constant = length(unique(pos[!is.na(pos)])) == 1 )
  })
  punct <- punct[ order( -vapply(punct, function(z) z$present_rate, 0) ) ]

  msk <- gsub("[a-z]", "a", gsub("[A-Z]", "A", gsub("[0-9]", "9", u)))
  mt  <- sort( tapply(cnt, msk, sum), decreasing = TRUE )

  list(
    n                 = n,
    n_missing         = n - length(xs) + n_sent,
    pct_missing       = round( (n - length(xs) + n_sent) / n, 4 ),
    n_unique          = nu,
    unique_ratio      = round( nu / N, 4 ),
    entropy           = round( H, 4 ),
    entropy_norm      = if( nu > 1 ) round( H / log(nu), 4 ) else NA_real_,
    top1_share        = round( cnt[1] / N, 4 ),
    charset           = charset,
    nchar_min         = min(L), nchar_max = max(L),
    nchar_mean        = round( mean(Lw), 2 ),
    nchar_sd          = round( sd(Lw), 3 ),
    fixed_width       = min(L) == max(L),
    has_leading_zeros = any( grepl("^0[0-9]", u) ),
    n_masks           = length(mt),
    mask_top          = names(mt)[1],
    mask_top_share    = round( mt[[1]] / N, 4 ),
    punctuation       = if( length(punct) ) .arr(punct) else .arr(list())
  )
}

## ---- value storage policy ------------------------------------------------

store_values <- function( x, order_is_signal = FALSE, seed = 1 ){

  xs <- as.character( x[ !is.na(x) ] )
  N  <- length(xs)
  tb <- sort( table(xs), decreasing = TRUE )
  nu <- length(tb)

  if( N <= 250 && order_is_signal ){
    return( list( storage_mode = "full", n_stored = N, is_lossless = TRUE,
                  seed = NA_integer_,
                  data = .arr( lapply(xs, function(v) list(value = v, count = 1L)) ) ) )
  }
  if( nu <= 150 ){
    return( list( storage_mode = "unique_weighted", n_stored = nu,
                  is_lossless = !order_is_signal, seed = NA_integer_,
                  data = .arr( lapply(seq_len(nu), function(i)
                           list(value = names(tb)[i], count = as.integer(tb[i]))) ) ) )
  }
  ## seed a local RNG stream, restore the caller's global state on exit
  if( exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE) ){
    .old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit( assign(".Random.seed", .old_seed, envir = .GlobalEnv), add = TRUE )
  } else {
    on.exit( suppressWarnings(rm(".Random.seed", envir = .GlobalEnv)), add = TRUE )
  }
  set.seed( seed )
  k   <- min( 100, nu )
  sel <- sample( nu, k, prob = as.numeric(tb) / N )
  sel <- sel[ order(-as.integer(tb[sel])) ]
  list( storage_mode = "sample_100", n_stored = k, is_lossless = FALSE,
        seed = seed,
        data = .arr( lapply(sel, function(i)
                 list(value = names(tb)[i], count = as.integer(tb[i]))) ) )
}

## ---- candidate shortlist from signature distance --------------------------
##
## Computed in pass 1 and STORED, so the labeller's input set is reproducible
## and its errors are auditable: it could only have chosen from this list.

shortlist_candidates <- function(x, ontology, k = 8, weights = SIGNATURE_WEIGHTS){
  sig <- fx_type_signature(x)
  ex  <- lapply(strsplit(ontology$examples, " *;; *"),
                function(z) z[nchar(trimws(z)) > 0])
  ok  <- which(lengths(ex) > 0)
  d <- vapply(ok, function(i)
         fx_signature_distance(sig, fx_type_signature(ex[[i]]), weights), numeric(1))
  keep <- order(d)[seq_len(min(k, length(d)))]
  lapply(seq_along(keep), function(j){
    i <- ok[keep[j]]
    list(rank               = j,
         semantic_type_id   = ontology$semantic_type_id[i],
         data_type          = ontology$data_type[i],
         semantic_family    = ontology$semantic_family[i],
         semantic_type      = ontology$semantic_type[i],
         fx_signature_distance = round(d[keep[j]], 4))
  })
}

## ---- assemble --------------------------------------------------------------

#' Build a banked test case from a column
#'
#' Profiles a column, computes its signature and candidate shortlist, and writes
#' a self-describing JSON test case (values, profile, label, difficulty) to the
#' bank directory. These cases are the replayable substrate for router training
#' and regression testing.
#'
#' @param x A column (coerced to character).
#' @param case_number Integer index used to mint the case id.
#' @param data_type,semantic_family,semantic_type,... Label fields and options
#'   (a later labelling pass may overwrite them).
#' @return Invisibly, a list with the written `path` and the case `obj`.
#' @seealso [fx_index_bank()], [fx_bank_coverage()]
#' @export
fx_make_test_case <- function( x, case_number,
    ## label (pass 2 may overwrite all of these)
    data_type = NA_character_, semantic_family = NA_character_,
    semantic_type = NA_character_, semantic_type_id = NA_character_,
    variant_id = NA_character_, depth_labeled = NA_integer_,
    label_confidence = NA_character_, label_method = "unlabeled",
    reviewer = NA_character_, relabeled = FALSE,
    relabel_reason = NA_character_, label_notes = NA_character_,
    ## difficulty
    difficulty = NA_character_, difficulty_rationale = NA_character_,
    noise_markers = character(0),
    ## provenance
    corpus = "manual", corpus_version = NA_character_,
    original_header = NA_character_, original_label = NA_character_,
    table_id = NA_character_, parent_case_id = NA_character_,
    ## ontology binding
    ontology = NULL, ontology_version = NA_character_,
    ontology_status = "in_ontology", proposed_parent = NA_character_,
    detector_exists = TRUE, hard_negative_for = character(0),
    ## mutation contract
    order_is_signal = FALSE, mutations_allowed = character(0),
    mutations_forbidden = character(0), mutation_target = NA_character_,
    ## output
    outdir = ".", n_candidates = 8 ){

  stopifnot(is.na(difficulty) || difficulty %in% c("easy","medium","hard"))
  if(isTRUE(relabeled) && is.na(relabel_reason))
    stop("relabel_reason is required when relabeled = TRUE")

  stem    <- if(!is.na(semantic_type)) semantic_type else "unlabeled"
  case_id <- sprintf("%s_%03d", stem, case_number)

  xs <- as.character(x[!is.na(x)])
  tb <- sort(table(xs), decreasing = TRUE)
  top10 <- lapply(seq_len(min(10, length(tb))), function(i)
    list(value = names(tb)[i], count = as.integer(tb[i]),
         share = round(as.integer(tb[i]) / length(xs), 4)))

  cands <- if(!is.null(ontology)) shortlist_candidates(x, ontology, k = n_candidates) else list()

  obj <- list(
    case_id        = case_id,
    schema_version = SCHEMA_VERSION,

    label = list(
      data_type = data_type, semantic_family = semantic_family,
      semantic_type = semantic_type, semantic_type_id = semantic_type_id,
      variant_id = variant_id,
      depth_labeled = depth_labeled,   # 1 = data_type only ... 3 = full path
      ontology_version = ontology_version,
      confidence = label_confidence,
      method = label_method,           # unlabeled|auto_agreement|llm|llm_reviewed|human
      reviewer = reviewer,
      labeled_on = if(identical(label_method,"unlabeled")) NA_character_ else format(Sys.Date()),
      relabeled = relabeled, relabel_reason = relabel_reason, notes = label_notes,
      needs_relabel = FALSE,           # written by ontology_diff() only
      relabel_trigger = NA_character_  # written by ontology_diff() only
    ),

    difficulty = list(rating = difficulty, rationale = difficulty_rationale,
                      noise_markers = .arr(as.list(noise_markers))),

    source = list(corpus = corpus, corpus_version = corpus_version,
                  original_header = original_header, original_label = original_label,
                  table_id = table_id, parent_case_id = parent_case_id,
                  retrieved = format(Sys.Date())),

    preview = list(top_10_unique = .arr(top10)),

    ontology = list(status = ontology_status, proposed_parent = proposed_parent,
                    detector_exists = detector_exists,
                    hard_negative_for = .arr(as.list(hard_negative_for)),
                    candidates = .arr(cands)),

    values  = store_values(x, order_is_signal = order_is_signal),
    profile = profile_vector(x),

    mutation = list(order_is_signal = order_is_signal,
                    allowed = .arr(as.list(mutations_allowed)),
                    forbidden = .arr(as.list(mutations_forbidden)),
                    target_difficulty = mutation_target),

    meta = list(
      extractor_version = if(exists("FEATURE_EXTRACTOR_VERSION")) FEATURE_EXTRACTOR_VERSION else NA_character_,
      tokenization = "case_folded;;split_on_non_alnum;;diacritics_preserved",
      sentinel_na_version = "1.0",
      created = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  )

  path <- file.path(outdir, paste0(case_id, ".json"))
  json_write(obj, path)
  invisible(list(path = path, obj = obj))
}

## ---- bank-level helpers ----------------------------------------------------

#' Index a directory of banked test cases
#'
#' Reads every `.json` case in a bank directory and returns one row per case
#' with its label, difficulty, ontology status, and profile size -- the flat
#' view used to audit and sample the bank.
#'
#' @param dir Bank directory (default the working directory).
#' @return A data frame, one row per case (empty if none). Requires `jsonlite`.
#' @seealso [fx_bank_coverage()], [fx_make_test_case()]
#' @export
fx_index_bank <- function(dir = "."){
  files <- list.files(dir, pattern = "\\.json$", full.names = TRUE)
  if(!length(files)) return(data.frame())
  if(!requireNamespace("jsonlite", quietly = TRUE))
    stop("fx_index_bank() needs jsonlite to read cases back")
  rows <- lapply(files, function(f){
    o <- jsonlite::fromJSON(f, simplifyVector = FALSE)
    data.frame(case_id = o$case_id,
               data_type = o$label$data_type %||% NA,
               semantic_family = o$label$semantic_family %||% NA,
               semantic_type = o$label$semantic_type %||% NA,
               semantic_type_id = o$label$semantic_type_id %||% NA,
               depth_labeled = o$label$depth_labeled %||% NA,
               ontology_version = o$label$ontology_version %||% NA,
               method = o$label$method %||% NA,
               needs_relabel = isTRUE(o$label$needs_relabel),
               difficulty = o$difficulty$rating %||% NA,
               status = o$ontology$status %||% NA,
               n = o$profile$n %||% NA, n_unique = o$profile$n_unique %||% NA,
               file = f, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

#' Coverage of a test-case bank by type and difficulty
#'
#' Cross-tabulates the banked cases by `semantic_type` and difficulty
#' (easy/medium/hard), so gaps in the regression corpus are visible at a glance.
#'
#' @param dir Bank directory (default the working directory).
#' @return A data frame of counts per semantic_type x difficulty.
#' @seealso [fx_index_bank()]
#' @export
fx_bank_coverage <- function(dir = "."){
  ix <- fx_index_bank(dir)
  if(!nrow(ix)) return(ix)
  tab <- as.data.frame.matrix(table(ix$semantic_type, ix$difficulty))
  for(d in c("easy","medium","hard")) if(is.null(tab[[d]])) tab[[d]] <- 0
  tab <- tab[, c("easy","medium","hard")]
  tab$N <- rowSums(tab); tab$pct_hard <- round(tab$hard / tab$N, 3)
  tab[order(-tab$N), ]
}
