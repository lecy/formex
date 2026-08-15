##############################
### Guess data type (detection workflow)
###############################
## Runtime orchestration that turns the atomized detectors (R/dt-<family>.R,
## registered in R/00-data-type-registry.R) into a best-guess, ONTOLOGY-anchored
## data-type prediction for a column. Keeps the detectors as pure predicates;
## all scoring/ranking/mapping lives here (the public seam of the module).
##
## Design (see conversation): on a large dataset this is meant to stay cheap ---
##   1. DEDUPE + SAMPLE: score at most `n_sample` unique values, not every cell.
##   2. FAST TIER first: run the fast detectors (all current ones). Only if none
##      clears `threshold` fall through to the slow tier (fuzzy matchers, none
##      yet) --- the `.slow_detectors` set makes this a no-op today.
##   3. RANK candidates by pass rate, breaking ties with a variable-NAME hint
##      and a specificity flag (loose detectors lose ties).
##   4. MAP the winner to ontology coordinates via data_type_ontology().


#' Score a column against every registered detector
#'
#' @param values A character vector (already sampled/deduped/cleaned).
#' @param detectors A named list of detector functions; defaults to the registry.
#' @return A data frame with `data_type`, `n`, `pass_rate`, ordered by descending
#'   `pass_rate`.
#' @export
score_data_type <- function(values, detectors = data_type_detectors()) {
  values <- as.character(values)
  values <- values[!is.na(values) & nzchar(trimws(values))]
  n <- length(values)
  rates <- vapply(detectors, function(f) {
    if (n == 0) return(NA_real_)
    mean(f(values), na.rm = TRUE)
  }, numeric(1))
  out <- data.frame(data_type = names(detectors), n = n,
                    pass_rate = unname(rates), stringsAsFactors = FALSE)
  out[order(-out$pass_rate), , drop = FALSE]
}

## variable-name keywords for a type (for the name hint)
#' @keywords internal
#' @noRd
.name_keywords <- function(nm) {
  onto <- data_type_ontology(nm)
  kw <- unique(c(strsplit(nm, "_")[[1]], onto[["data_class"]], onto[["data_type"]]))
  kw <- tolower(kw[!is.na(kw)])
  kw[nchar(kw) >= 3]
}

## does the variable name hint at this type?
#' @keywords internal
#' @noRd
.name_hits <- function(nm, varname) {
  if (is.null(varname) || is.na(varname) || !nzchar(varname)) return(FALSE)
  v <- tolower(varname)
  any(vapply(.name_keywords(nm), function(k) grepl(k, v, fixed = TRUE), logical(1)))
}

## ---------------------------------------------------------------------------
## ROUTER -> VERIFIER (v6 ontology)
##
## The detector scoring above is the legacy flat-registry path (kept intact --
## many tests + guess_column() depend on `$guess`/`$ontology`). This block adds
## the two-stage v6 flow the datagoodr integration consumes:
##
##   ROUTER    a cheap, shippable shortlist. fx_type_signature() reduces the
##             column to a 7-number signature; shortlist_candidates() ranks the
##             ontology rows by signature distance to their examples. No ML
##             model to ship -- the signature IS the router. (The learned
##             476-feature router is a separate, heavier deploy: it needs a
##             saved model + the v2 extractor ported into the package.)
##   VERIFIER  deterministic confirm = detect o transform. For each shortlisted
##             variant we run its recipe (raw_to_stable_transform) over the
##             sample; the confirm rate = share that normalizes+validates to a
##             non-NA stable value. This is exactly the ready-to-stabilize
##             signal, reused as evidence. Only DISCRIMINATING match_kinds
##             (genome/mask/lexicon/mask+lexicon) can confirm a leaf; identity
##             recipes (none/shape) confirm trivially, so they never win on
##             confirm -- they fall back to the router and truncate.
##
## The result GRACEFULLY TRUNCATES: a confirmed variant resolves the full path
## (depth 4, format_label included); an unconfirmed column resolves only as deep
## as the router shortlist agrees (data_type -> family -> semantic_type).
## ---------------------------------------------------------------------------

## A fixed foil of junk strings spanning shapes (nonsense words/phrases, mixed
## alnum, punctuation, bare numbers, impossible dates). The verifier runs each
## candidate recipe on BOTH the column and this foil: a VALIDATING recipe (date
## genome, checksum mask, closed-set lexicon) confirms the column but rejects
## the foil (low "leak"); a COERCING recipe (as_factor / as_num / identity)
## confirms the foil too. Empirical selectivity -- confirm high AND leak low --
## is what earns a leaf, so non-selective numeric subtypes and free-text
## truncate to the router-agreed ancestor instead of claiming a false leaf.
#' @keywords internal
#' @noRd
.FX_FOIL <- c(
  "qxzptr", "vbnmlk", "zzxywq", "jkqvxz", "wqpzrn", "xcvbnm",
  "foo bar baz", "lorem ipsum", "hello world foo",
  "a1b2c3", "x9y8z7", "q4w5e6d8", "zz99xx11",
  "!@#$%^", "...///", "--__--", "<<>>||",
  "42", "3.14159", "1000000", "0.5",
  "2020-13-45", "99/99/9999")

#' @keywords internal
#' @noRd
.fx_confirm_rate <- function(vals, expr) {
  if (is.na(expr) || !nzchar(trimws(expr))) return(NA_real_)
  st <- tryCatch(fx_transform(vals, expr),
                 error = function(e) rep(NA_character_, length(vals)))
  if (isTRUE(attr(st, "unimplemented"))) return(NA_real_)
  mean(!is.na(st))
}

#' @keywords internal
#' @noRd
.fx_route_verify <- function(u, ont = fx_ontology(), router_k = 8,
                             confirm_thr = 0.80, leak_max = 0.25,
                             margin = 0.50, sig_floor = 0.55,
                             prefer_router = "auto") {
  blank <- function(depth = 0L, conf = NA_real_, router = NULL, verified = NULL)
    list(data_type = NA_character_, semantic_family = NA_character_,
         semantic_type = NA_character_, semantic_type_id = NA_character_,
         variant_id = NA_character_, format_label = NA_character_,
         match_kind = NA_character_, depth = depth, confidence = conf,
         dd_unit = NA_character_, router_method = NA_character_,
         candidates = list(router = router, verified = verified))

  if (length(u) == 0) return(blank())

  ## ---- ROUTER: learned model first, signature shortlist as fallback -------
  router <- .fx_shortlist(u, ont, k = router_k, prefer = prefer_router)
  if (is.null(router) || !nrow(router)) return(blank())
  router_method <- attr(router, "router")
  if (is.null(router_method)) router_method <- "signature"

  ## ---- VERIFIER: confirm on the column, leak on the foil, per variant -----
  ## Candidate set = the router shortlist PLUS the always-on selective kinds
  ## (genome + mask+lexicon: dates, datetimes, person names). The signature
  ## router confuses these with identifiers/hashes, so their recipes are always
  ## verified regardless of the shortlist; the foil gate blocks false leaves.
  always <- ont$match_kind %in% c("genome", "mask+lexicon")
  vr <- ont[ont$semantic_type_id %in% unique(router$semantic_type_id) | always, ,
            drop = FALSE]
  vr$confirm <- vapply(vr$raw_to_stable_transform,
                       function(e) .fx_confirm_rate(u, e), numeric(1))
  vr$leak    <- vapply(vr$raw_to_stable_transform,
                       function(e) .fx_confirm_rate(.FX_FOIL, e), numeric(1))
  vr$selectivity <- vr$confirm - ifelse(is.na(vr$leak), 0, vr$leak)
  vr$router_sim  <- router$router_sim[match(vr$semantic_type_id,
                                            router$semantic_type_id)]
  verified <- vr[order(-ifelse(is.na(vr$selectivity), -1, vr$selectivity)),
                 c("semantic_type_id", "variant_id", "semantic_type",
                   "format_label", "match_kind", "confirm", "leak",
                   "selectivity", "router_sim")]
  rownames(verified) <- NULL

  ## ---- DECISION ------------------------------------------------------------
  ## Temporal disambiguation: the date genome recipes are mutually tolerant
  ## (as_mmddyyyy parses a datetime, as_datetime parses a bare date), so
  ## confirm alone cannot separate calendar / timestamp / clock. Break that tie
  ## by the raw column's own content -- does it carry a clock time, a date, or
  ## both -- and prefer the granularity that loses no information.
  has_time <- mean(grepl("[0-2]?[0-9]:[0-5][0-9]", u)) >= 0.5
  has_date <- mean(grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{2,4}",
                         u)) >= 0.5
  tbonus <- rep(0, nrow(vr))
  tbonus[vr$semantic_type == "timestamp"] <- if ( has_time &&  has_date) 1 else 0
  tbonus[vr$semantic_type == "calendar"]  <- if ( has_date && !has_time) 1 else 0
  tbonus[vr$semantic_type == "clock"]     <- if ( has_time && !has_date) 1 else 0

  ## 1) a SELECTIVE variant (confirms the column, rejects the foil) -> leaf
  sel <- !is.na(vr$confirm) & vr$confirm >= confirm_thr &
         (is.na(vr$leak) | vr$leak <= leak_max) & vr$selectivity >= margin
  if (any(sel)) {
    rs <- ifelse(is.na(vr$router_sim), 0, vr$router_sim)
    w  <- which(sel)[order(-tbonus[sel], -vr$selectivity[sel], -vr$confirm[sel],
                           -rs[sel])[1]]
    r  <- vr[w, ]
    dd <- r$dd_data_unit
    out <- list(
      data_type = r$data_type, semantic_family = r$semantic_family,
      semantic_type = r$semantic_type, semantic_type_id = r$semantic_type_id,
      variant_id = r$variant_id, format_label = r$format_label,
      match_kind = r$match_kind, depth = 4L, confidence = r$confirm,
      dd_unit = if (!is.na(dd) && nzchar(trimws(dd))) dd else NA_character_,
      router_method = router_method,
      candidates = list(router = router, verified = verified))
    return(out)
  }

  ## 2) nothing selective -> router only, truncate to the confident depth.
  ## The two routers score on different scales, so truncation differs:
  ##  - signature: shortlist agreement (top-k share data_type/family/type)
  ##    gated by a similarity floor;
  ##  - learned: the top-1 CLASS PROBABILITY sets the depth directly (the
  ##    shortlist is a ranking of different classes, so agreement is moot).
  top <- router[1, ]
  if (identical(router_method, "learned")) {
    p1    <- top$router_sim
    depth <- if (p1 >= 0.50) 3L else if (p1 >= 0.25) 1L else 0L
  } else {
    if (top$router_sim < sig_floor)
      return(blank(depth = 0L, conf = top$router_sim,
                   router = router, verified = verified))
    agree_type   <- length(unique(router$data_type))       == 1L
    agree_family <- agree_type   && length(unique(router$semantic_family)) == 1L
    agree_st     <- agree_family && length(unique(router$semantic_type))   == 1L
    depth <- if (agree_st) 3L else if (agree_family) 2L else 1L
  }
  if (depth == 0L)
    return(blank(depth = 0L, conf = top$router_sim,
                 router = router, verified = verified))
  rec <- blank(depth = depth, conf = top$router_sim,
               router = router, verified = verified)
  rec$router_method <- router_method
  rec$data_type <- top$data_type
  if (depth >= 2L) rec$semantic_family <- top$semantic_family
  if (depth >= 3L) { rec$semantic_type    <- top$semantic_type
                     rec$semantic_type_id <- top$semantic_type_id }
  rec
}

#' Guess the ontology-anchored data type of a column
#'
#' Reads up to `n_sample` unique values and returns two aligned views of the
#' column's type. The LEGACY view scores the values against every registered
#' detector and reports the best-matching type (when its pass rate clears
#' `threshold`) with its flat-ontology coordinates. The `route` view runs the
#' v6 two-stage flow: a signature-based ROUTER shortlists ontology candidates,
#' then a deterministic VERIFIER (confirm = detect o transform) confirms a leaf
#' or gracefully truncates to the depth the router agrees on.
#'
#' @param x A vector (coerced to character) of column values.
#' @param name Optional variable name; used only to break ties (e.g. a column
#'   named `fips` favors a FIPS detector over a same-shape ZIP detector).
#' @param n_sample Maximum number of unique non-missing values to test.
#' @param threshold Minimum pass rate for the top type to be reported as the
#'   legacy `guess`; below it, `guess` is `NA` (unknown).
#' @param floor Minimum pass rate for a type to appear in `candidates`.
#' @param detectors A named list of detector functions; defaults to the registry.
#' @param seed Optional integer seed for reproducible sampling.
#' @param route If `TRUE` (default), also compute the v6 router->verifier
#'   `route` record. Set `FALSE` to skip it (pure legacy behavior).
#' @param ontology The v6 ontology used by the router/verifier; defaults to
#'   [fx_ontology()].
#' @param router_k Router shortlist size (candidates handed to the verifier).
#' @param confirm_thr Minimum verifier confirm rate for a discriminating variant
#'   to resolve a full leaf (depth 4).
#' @param sig_floor Minimum router similarity for any non-`NA` route guess
#'   (signature router only).
#' @param router Which Stage-1 router to use: `"auto"` (default) prefers the
#'   learned xgboost model in `inst/extdata/router_xgb.rds` and falls back to
#'   the signature router when xgboost or the artifact is unavailable;
#'   `"learned"` forces the model (route is `NA` if unavailable); `"signature"`
#'   forces the model-free signature router. `route$router_method` reports which
#'   ran.
#'
#' @return A list with the legacy fields:
#'   \describe{
#'     \item{guess}{Best-matching detector type name, or `NA`.}
#'     \item{ontology}{Named vector `c(data_type, data_subtype, data_class,
#'       data_format)` for the guess (all `NA` if none).}
#'     \item{confidence}{The guess's pass rate.}
#'     \item{candidates}{Ranked data frame of types clearing `floor`.}
#'     \item{n}{Number of unique values scored.}
#'   }
#'   and, when `route = TRUE`, a `route` sub-list anchored to the v6 ontology:
#'   `data_type`, `semantic_family`, `semantic_type`, `semantic_type_id`,
#'   `variant_id`, `format_label`, `match_kind`, `depth` (0 = unknown, 1 =
#'   data_type, 2 = family, 3 = semantic_type, 4 = leaf/format), `confidence`,
#'   `dd_unit`, and `candidates` (the `router` shortlist + `verified` table).
#'
#' @examples
#' guess_data_type(c("USD", "EUR", "JPY", "GBP"))$ontology
#' guess_data_type(c("06037", "36061"), name = "county_fips")$guess
#' guess_data_type(c("03/15/2019", "12/31/2020"))$route$format_label  # calendar
#'
#' @seealso [score_data_type()], [fx_stabilize()], [fx_ontology()]
#' @export
guess_data_type <- function(x, name = NULL, n_sample = 100, threshold = 0.8,
                            floor = 0.5, detectors = data_type_detectors(),
                            seed = NULL, route = TRUE, ontology = NULL,
                            router_k = 8, confirm_thr = 0.80, sig_floor = 0.55,
                            router = c("auto", "learned", "signature")) {
  router <- match.arg(router)
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(trimws(x))]
  u <- unique(x)
  if (length(u) > n_sample) {
    if (!is.null(seed)) set.seed(seed)
    u <- sample(u, n_sample)
  }

  ## --- fast tier, then fall through to slow only if nothing is confident ----
  is_slow <- names(detectors) %in% .slow_detectors
  scores <- score_data_type(u, detectors[!is_slow])
  if ((nrow(scores) == 0 || max(scores$pass_rate, na.rm = TRUE) < threshold) &&
      any(is_slow)) {
    scores <- rbind(scores, score_data_type(u, detectors[is_slow]))
    scores <- scores[order(-scores$pass_rate), , drop = FALSE]
  }

  ## --- annotate with tie-breakers, filter to candidates, rank ---------------
  scores$name_match <- vapply(scores$data_type, .name_hits, logical(1),
                              varname = name)
  scores$specific   <- !(scores$data_type %in% .loose_detectors)
  cand <- scores[!is.na(scores$pass_rate) & scores$pass_rate >= floor, ,
                 drop = FALSE]
  cand <- cand[order(-round(cand$pass_rate, 3), -cand$name_match,
                     -cand$specific), , drop = FALSE]
  rownames(cand) <- NULL

  top <- if (nrow(cand)) cand[1, ] else NULL
  guess <- if (!is.null(top) && top$pass_rate >= threshold) top$data_type else NA_character_

  out <- list(
    guess = guess,
    ontology = if (is.na(guess)) data_type_ontology(NA) else data_type_ontology(guess),
    confidence = if (is.null(top)) NA_real_ else top$pass_rate,
    candidates = cand,
    n = length(u)
  )

  ## --- v6 router -> verifier record (the shippable two-stage flow) ----------
  if (isTRUE(route)) {
    ont <- if (is.null(ontology)) tryCatch(fx_ontology(), error = function(e) NULL)
           else ontology
    out$route <- if (is.null(ont)) NULL
                 else tryCatch(.fx_route_verify(u, ont, router_k = router_k,
                                                confirm_thr = confirm_thr,
                                                sig_floor = sig_floor,
                                                prefer_router = router),
                               error = function(e) NULL)
  }
  out
}
