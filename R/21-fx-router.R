## ===========================================================================
## Learned router  (Stage 1 of guess_data_type()'s router -> verifier flow)
##
## The signature router (fx_type_signature + shortlist_candidates, R/11-R/12) is
## the always-available, model-free shortlist. This module adds the LEARNED
## router: an xgboost model over the full fx_extract_features() profile, trained
## in data-raw/train_router.R and shipped as inst/extdata/router_xgb.rds.
##
## Parity guarantee: the artifact was trained on features from THIS extractor
## (fx_extract_features), so the inference matrix is column-identical to the
## training matrix -- the model, the feature names, the column order, and the
## median imputations all travel together in the artifact.
##
## Everything degrades gracefully: if xgboost is not installed or the artifact
## is absent/unreadable, .fx_shortlist() silently falls back to the signature
## router. The downstream verifier (.fx_route_verify) is identical either way --
## it only consumes a ranked table of semantic_type_ids.
## ===========================================================================

## cache the reconstructed booster + metadata across calls in one session
.fx_router_cache <- new.env(parent = emptyenv())

#' @keywords internal
#' @noRd
.fx_router_artifact <- function() {
  if (exists("art", envir = .fx_router_cache, inherits = FALSE))
    return(get("art", envir = .fx_router_cache))
  art <- NULL
  if (requireNamespace("xgboost", quietly = TRUE)) {
    p <- tryCatch(system.file("extdata", "router_xgb.rds", package = "formex"),
                  error = function(e) "")
    if (is.null(p) || !nzchar(p) || !file.exists(p)) {
      ## dev fallback: search up from the working dir (devtools::test() runs in
      ## tests/testthat/, so the package-root path is a few levels up)
      cand <- file.path(c(".", "..", "../..", "../../.."),
                        "inst", "extdata", "router_xgb.rds")
      hit  <- cand[file.exists(cand)]
      p <- if (length(hit)) hit[1] else ""
    }
    if (nzchar(p) && file.exists(p)) {
      art <- tryCatch({
        a <- readRDS(p)
        a$booster <- xgboost::xgb.load.raw(a$raw)
        a
      }, error = function(e) NULL)
    }
  }
  assign("art", art, envir = .fx_router_cache)
  art
}

## Build the router shortlist as a data.frame with the columns the verifier
## expects: rank, semantic_type_id, data_type, semantic_family, semantic_type,
## distance, router_sim. `method` attribute records which router produced it.
#' @keywords internal
#' @noRd
.fx_learned_shortlist <- function(u, ont, k = 8, art = .fx_router_artifact()) {
  if (is.null(art)) return(NULL)
  f <- tryCatch(fx_extract_features(u), error = function(e) NULL)
  if (is.null(f)) return(NULL)
  ## align to the trained feature columns + order; impute like training
  row <- setNames(rep(NA_real_, length(art$features)), art$features)
  nm  <- intersect(names(f), art$features)
  row[nm] <- as.numeric(unlist(f[nm]))
  bad <- !is.finite(row)
  if (any(bad)) row[bad] <- art$medians[names(row)[bad]]
  row[!is.finite(row)] <- 0
  X <- matrix(row, nrow = 1, dimnames = list(NULL, art$features))

  ## multi:softprob returns a 1xK matrix (or length-K vector on older xgboost);
  ## `reshape` was removed in xgboost 3.x, so coerce defensively instead.
  p <- tryCatch(stats::predict(art$booster, X), error = function(e) NULL)
  if (is.null(p)) return(NULL)
  p <- as.numeric(p)
  if (length(p) != length(art$levels)) return(NULL)
  names(p) <- art$levels
  ord <- order(-p)[seq_len(min(k, length(p)))]
  ids <- art$levels[ord]

  ## map each predicted semantic_type_id to its ontology coordinates
  idx <- match(ids, ont$semantic_type_id)
  keep <- !is.na(idx)
  if (!any(keep)) return(NULL)
  ids <- ids[keep]; idx <- idx[keep]; probs <- p[ord][keep]
  data.frame(
    rank             = seq_along(ids),
    semantic_type_id = ids,
    data_type        = ont$data_type[idx],
    semantic_family  = ont$semantic_family[idx],
    semantic_type    = ont$semantic_type[idx],
    distance         = round(1 - probs, 4),
    router_sim       = round(probs, 4),
    stringsAsFactors = FALSE)
}

#' @keywords internal
#' @noRd
.fx_signature_shortlist <- function(u, ont, k = 8) {
  cand <- tryCatch(shortlist_candidates(u, ont, k = k), error = function(e) NULL)
  if (is.null(cand) || !length(cand)) return(NULL)
  router <- data.frame(
    rank             = vapply(cand, `[[`, integer(1),   "rank"),
    semantic_type_id = vapply(cand, `[[`, character(1), "semantic_type_id"),
    data_type        = vapply(cand, `[[`, character(1), "data_type"),
    semantic_family  = vapply(cand, `[[`, character(1), "semantic_family"),
    semantic_type    = vapply(cand, `[[`, character(1), "semantic_type"),
    distance         = vapply(cand, `[[`, numeric(1),   "fx_signature_distance"),
    stringsAsFactors = FALSE)
  router$router_sim <- 1 - router$distance
  router
}

## the shortlist entry point: learned router first, signature router as fallback.
## `prefer` = "auto" (default), "learned", or "signature".
#' @keywords internal
#' @noRd
.fx_shortlist <- function(u, ont, k = 8, prefer = c("auto", "learned", "signature")) {
  prefer <- match.arg(prefer)
  if (prefer != "signature") {
    sl <- .fx_learned_shortlist(u, ont, k = k)
    if (!is.null(sl) && nrow(sl) > 0) { attr(sl, "router") <- "learned"; return(sl) }
    if (prefer == "learned") return(NULL)
  }
  sl <- .fx_signature_shortlist(u, ont, k = k)
  if (!is.null(sl)) attr(sl, "router") <- "signature"
  sl
}
