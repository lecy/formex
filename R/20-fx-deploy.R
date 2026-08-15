## ===========================================================================
## 20-fx-deploy.R  --  the deployment seam: ONE entry point that enforces
## sampling and block-gating, so callers cannot accidentally run the expensive
## feature blocks over a full high-cardinality column.
##
## Why this file exists
## --------------------
## Two runtime facts make an un-guarded call slow:
##   1. fx_extract_features() does NOT sample -- it computes ~200 vectorized
##      string passes over EVERY unique value (only capped at max_unique=20000).
##      Feed it a 400k-distinct free-text/ID column and it grinds for seconds.
##   2. guess_data_type() DOES sample (n_sample uniques), but that is a second,
##      independent sample -- nothing guarantees the two modalities see the same
##      values, or that either one is gated to the blocks the fitted model uses.
##
## fx_classify_column() closes both gaps: it draws ONE row sample, runs the
## (block-gated) feature extractor and the detector over material derived from
## that same sample, optionally patches the whole-column cardinality features
## back in with a single cheap pass, and hands the feature row to a pluggable
## scorer. When trained weights are packaged, pass them as `cascade=` and the
## sampling / gating code below does not change.
##
## Requires: 10-fx-features.R, 02-01-guess-data-type.R, 02-02-classify-by-name.R
## ===========================================================================

## ---------------------------------------------------------------------------
## reproducible, non-invasive row sampler
##
## Random ROW sample (not unique-value sample): this preserves the frequency
## distribution, which every frequency-weighted feature block (`w`) depends on,
## and it naturally surfaces the common formats. Rare-but-present formats can be
## missed -- that is the accepted cost of not touching the whole column. Whole-
## column cardinality is restored separately (see `cardinality=` below).
## ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.fx_row_sample <- function(x, n_rows = 500L, seed = 1L) {
  keep <- !is.na(x)
  xk   <- x[keep]
  if (is.character(xk) || is.factor(xk)) {
    xc <- as.character(xk)
    xk <- xk[nzchar(trimws(xc))]
  }
  n <- length(xk)
  if (n <= n_rows) return(xk)

  ## seed a local RNG draw and restore the caller's global stream, matching the
  ## non-invasive pattern in fx_extract_features().
  if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    .old <- get(".Random.seed", envir = .GlobalEnv)
    on.exit(assign(".Random.seed", .old, envir = .GlobalEnv), add = TRUE)
  } else {
    on.exit(suppressWarnings(rm(".Random.seed", envir = .GlobalEnv)), add = TRUE)
  }
  set.seed(seed)
  xk[sample.int(n, n_rows)]
}

## ---------------------------------------------------------------------------
## resolve which feature blocks to compute
##
## Priority: explicit `blocks` > blocks derived from the fitted model's
## `features_used` > the full development set. Deriving from the model is the
## point of the manifest: compute only what the weights reference, skipping the
## tier-2/tier-3 blocks (charfreq, regex, token, and especially lexicon) when
## they are unused.
## ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
.fx_resolve_blocks <- function(blocks, features_used, manifest, lexicons) {
  if (!is.null(blocks))        return(blocks)
  if (!is.null(features_used)) {
    if (is.null(manifest)) manifest <- fx_feature_manifest(lexicons)
    return(fx_blocks_for_features(features_used, manifest))
  }
  ALL_BLOCKS
}

#' Classify a single column under deployment rules (sample + gate + score)
#'
#' The deployment entry point for one column. Draws a single row sample, runs
#' the block-gated feature extractor and the value/name detector over it, and
#' returns a prediction plus the feature row. This is the only place that should
#' call [fx_extract_features()] in production, because it is the only place that
#' guarantees the extractor never runs un-sampled.
#'
#' @param x A column (any vector).
#' @param name Optional column header, used by the detector's name tie-break and
#'   the header feature block.
#' @param n_rows Row-sample size for the expensive feature blocks and detection.
#'   A few hundred is enough for format detection; see the package notes on the
#'   speed/coverage trade-off.
#' @param blocks Explicit feature blocks to compute; overrides `features_used`.
#' @param features_used Character vector of the feature names the fitted model
#'   references; blocks are derived from these via [fx_feature_manifest()].
#'   Ignored when `blocks` is supplied.
#' @param manifest Optional precomputed [fx_feature_manifest()] (pass it in a
#'   batch so it is not rebuilt per column).
#' @param cardinality `"full"` (default) recomputes the whole-column cardinality
#'   features (`n_unique`, `unique_ratio`, `hapax_ratio`, ...) with one extra
#'   linear pass, so those features are exact even though the string blocks were
#'   sampled. `"sample"` skips that pass entirely -- fastest, but cardinality
#'   features then describe the sample, not the column.
#' @param cascade Optional scorer: a function of the one-row feature data frame
#'   returning a list with at least `guess`, `confidence`, and `ontology`. When
#'   `NULL`, falls back to the rule-based [guess_column()].
#' @param detectors Named list of detector functions; pass the result of
#'   [data_type_detectors()] once in a batch to avoid re-resolving ~90 functions
#'   per column. Ignored when `cascade` is supplied.
#' @param lexicons Lexicon set for the lexicon block; defaults to
#'   [default_lexicons()].
#' @param threshold Minimum detector pass rate to trust a value guess.
#' @param seed Sampling seed (features and detection stay reproducible).
#'
#' @return A list: `column`, `source`, `guess`, `confidence`, `ontology`,
#'   `features` (one-row data frame), `blocks`, `n` (usable rows seen for
#'   cardinality), `n_unique`, and `n_sampled`.
#' @seealso [fx_classify_df()], [fx_extract_features()], [guess_column()]
#' @export
fx_classify_column <- function(x, name = NULL,
                               n_rows = 500L,
                               blocks = NULL,
                               features_used = NULL,
                               manifest = NULL,
                               cardinality = c("full", "sample"),
                               cascade = NULL,
                               detectors = NULL,
                               lexicons = default_lexicons(),
                               threshold = 0.8,
                               seed = 1L) {
  cardinality <- match.arg(cardinality)
  blocks <- .fx_resolve_blocks(blocks, features_used, manifest, lexicons)

  ## --- one sample, shared by both modalities ------------------------------
  samp <- .fx_row_sample(x, n_rows = n_rows, seed = seed)

  ## --- feature engineering (block-gated) over the sample ------------------
  feat <- fx_extract_features(samp, col_name = name, blocks = blocks,
                              lexicons = lexicons, seed = seed)

  ## --- exact whole-column cardinality, one cheap pass, no regex blocks ----
  ## Re-run only the `core` block on the FULL column and overwrite the sampled
  ## core features. core reads value COUNTS, so it is linear and vectorized --
  ## this is the single deliberate full-column touch, skipped under "sample".
  if (cardinality == "full" && "core" %in% blocks) {
    core_full <- fx_extract_features(x, col_name = name, blocks = "core",
                                     lexicons = lexicons, seed = seed)
    for (k in names(core_full)) feat[[k]] <- core_full[[k]]
  }
  n_unique <- if (!is.null(feat[["n_unique"]])) feat[["n_unique"]] else NA_real_
  n_usable <- if (!is.null(feat[["n_usable"]])) feat[["n_usable"]] else NA_real_

  ## --- scoring: fitted cascade if supplied, else the rule-based ensemble --
  if (!is.null(cascade)) {
    res <- cascade(feat)
    src <- if (!is.null(res$source)) res$source else "cascade"
    onto <- if (!is.null(res$ontology)) res$ontology else data_type_ontology(NA)
    guess <- if (!is.null(res$guess)) res$guess else NA_character_
    conf  <- if (!is.null(res$confidence)) res$confidence else NA_real_
  } else {
    det <- if (!is.null(detectors)) detectors else data_type_detectors()
    g <- guess_column(samp, name = name, threshold = threshold, detectors = det)
    src <- g$source; onto <- g$ontology; guess <- g$guess; conf <- g$confidence
  }

  list(column = name, source = src, guess = guess, confidence = conf,
       ontology = onto, features = feat, blocks = blocks,
       n = n_usable, n_unique = n_unique, n_sampled = length(samp))
}

#' Classify every column of a data frame under deployment rules
#'
#' Batch driver over [fx_classify_column()]. Resolves the detector list (or the
#' feature manifest) ONCE and reuses it across columns, then returns a tidy
#' one-row-per-column prediction table. Feature rows are attached as an attribute
#' (`"features"`) for callers that want them.
#'
#' @param df A data frame (or list of columns).
#' @param cols Which columns to classify; defaults to all.
#' @param n_rows,blocks,features_used,cardinality,cascade,lexicons,threshold,seed
#'   Passed through to [fx_classify_column()].
#'
#' @return A data frame with `column`, `source`, `guess`, `confidence`,
#'   `data_type`, `data_class`, `n`, `n_unique`, `n_sampled`. The per-column
#'   feature rows are bound into a data frame stored in `attr(., "features")`.
#' @seealso [fx_classify_column()]
#' @export
fx_classify_df <- function(df, cols = names(df),
                           n_rows = 500L,
                           blocks = NULL,
                           features_used = NULL,
                           cardinality = c("full", "sample"),
                           cascade = NULL,
                           lexicons = default_lexicons(),
                           threshold = 0.8,
                           seed = 1L) {
  cardinality <- match.arg(cardinality)

  ## resolve the expensive-to-build objects ONCE, not per column
  det <- if (is.null(cascade)) data_type_detectors() else NULL
  manifest <- if (is.null(blocks) && !is.null(features_used))
    fx_feature_manifest(lexicons) else NULL

  res <- lapply(cols, function(nm) {
    fx_classify_column(df[[nm]], name = nm, n_rows = n_rows, blocks = blocks,
                       features_used = features_used, manifest = manifest,
                       cardinality = cardinality, cascade = cascade,
                       detectors = det, lexicons = lexicons,
                       threshold = threshold, seed = seed)
  })

  pred <- do.call(rbind, lapply(res, function(r) data.frame(
    column     = if (is.null(r$column)) NA_character_ else r$column,
    source     = r$source,
    guess      = if (is.null(r$guess) || is.na(r$guess)) NA_character_ else r$guess,
    confidence = r$confidence,
    data_type  = unname(r$ontology[["data_type"]]),
    data_class = unname(r$ontology[["data_class"]]),
    n          = r$n, n_unique = r$n_unique, n_sampled = r$n_sampled,
    stringsAsFactors = FALSE)))
  pred$column <- cols

  ## bind feature rows (they may differ in columns if blocks vary; align)
  frows <- lapply(res, `[[`, "features")
  allnm <- unique(unlist(lapply(frows, names)))
  frows <- lapply(frows, function(f) {
    for (m in setdiff(allnm, names(f))) f[[m]] <- NA_real_
    f[, allnm, drop = FALSE]
  })
  attr(pred, "features") <- cbind(column = cols, do.call(rbind, frows),
                                  stringsAsFactors = FALSE)
  pred
}
