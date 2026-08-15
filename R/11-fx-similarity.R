## ===========================================================================
## type_similarity.R -- minimal orthogonal signature for measuring how
## confusable two semantic types are, independent of where they sit in the
## ontology.
##
## Two distances, deliberately kept separate:
##   fx_path_distance()      a priori, from the taxonomy   -- what SHOULD be near
##   fx_signature_distance() empirical, from the data      -- what LOOKS near
##
## The disagreement between them is the useful output. Pairs that are far in
## the taxonomy but near in signature space are the dangerous confusions
## (identifiers vs dates). Pairs near in the taxonomy but far in signature
## space suggest a split made on meaning rather than on guessability.
##
## Requires: extract_features2.R
## ===========================================================================

## ---------------------------------------------------------------------------
## The seven axes
##
## Selected by profiling the ontology's own examples, computing the candidate
## correlation matrix, and keeping one representative per collinear cluster.
## The clusters found empirically (|r| > 0.8) were:
##
##   rigidity      mask_top_share ~ cmask_top_share ~ n_masks ~ mask_entropy
##                 ~ is_fixed_width          (r from 0.80 to 0.98)
##   tokenization  pct_chr_space ~ tok_mean ~ pct_single_tok   (r 0.86-0.90)
##   composition   pct_chr_digit ~ pct_chr_alpha               (r -0.85)
##
## So "is it fixed width", "how uniform is the mask", and "how many masks are
## there" are NOT three dimensions -- they are one. Using all of them would
## triple-count pattern rigidity and silently dominate the score.
##
## numeric_gap is an orthogonalization, not a raw feature: coerce_rate and
## digit share correlate at r = 0.72, but their DIFFERENCE is the useful
## quantity -- digit-heavy strings that do not parse as numbers are exactly
## the identifier / date / phone / postal family.
## ---------------------------------------------------------------------------

SIGNATURE_AXES <- c(
  composition  = "share of characters that are digits",
  numeric_gap  = "parses as a number beyond what digit content alone implies",
  rigidity     = "share of values sharing the single dominant mask",
  width        = "mean value length, log-scaled",
  punctuation  = "share of characters that are punctuation",
  tokenization = "share of values that are a single token",
  cardinality  = "distinct values as a share of non-missing values"
)

## Default weights. Set an axis to 0 to ignore it; raise one to emphasize a
## dimension you care about. Format-level comparisons usually want cardinality
## down-weighted (two date formats differ in shape, not in how many distinct
## dates a column holds).
#' Signature axis weights (balanced default)
#'
#' Per-axis weights for [fx_signature_distance()]. Set an axis to 0 to ignore
#' it, or raise one to emphasize it. `SIGNATURE_WEIGHTS` weights all seven axes
#' equally; [WEIGHTS_FORMAT] is tuned for format-level comparisons.
#'
#' @format A named numeric vector over the seven signature axes.
#' @seealso [fx_signature_distance()], [WEIGHTS_FORMAT]
#' @export
SIGNATURE_WEIGHTS <- c(composition = 1, numeric_gap = 1, rigidity = 1,
                       width = 1, punctuation = 1, tokenization = 1,
                       cardinality = 1)

#' Signature axis weights tuned for format comparisons
#'
#' A weighting for [fx_signature_distance()] that emphasizes shape (rigidity,
#' width, punctuation) and down-weights cardinality to 0, because two formats of
#' the same type differ in shape, not in how many distinct values a column holds.
#'
#' @format A named numeric vector over the seven signature axes.
#' @seealso [fx_signature_distance()], [SIGNATURE_WEIGHTS]
#' @export
WEIGHTS_FORMAT <- c(composition = 1, numeric_gap = 0.5, rigidity = 2,
                    width = 2, punctuation = 2, tokenization = 1,
                    cardinality = 0)

## ---------------------------------------------------------------------------
## fx_type_signature() -- 7 numbers, each scaled to [0,1]
## ---------------------------------------------------------------------------

#' Reduce a column to its 7-number type signature
#'
#' Collapses a column's value profile to seven interpretable axes, each scaled
#' to `[0,1]`: composition, numeric_gap, rigidity, width, punctuation,
#' tokenization, and cardinality. The signature is the model-free router's view
#' of a column and the input to [fx_signature_distance()].
#'
#' @param x A column (coerced to character).
#' @param features Optional precomputed [fx_extract_features()] row; computed
#'   from `x` when `NULL`.
#' @return A named numeric vector of the seven axes (`NA` where undefined).
#' @seealso [fx_signature_distance()], [fx_extract_features()]
#' @export
fx_type_signature <- function( x, features = NULL ){

  f <- if(is.null(features))
         fx_extract_features(x, blocks = c("core","length","charclass","mask",
                                        "numeric","token"))
       else features

  g <- function(k) if(is.null(f[[k]]) || length(f[[k]]) != 1) NA_real_ else as.numeric(f[[k]])
  clamp <- function(v, lo = 0, hi = 1) if(is.na(v)) NA_real_ else max(lo, min(hi, v))

  dig <- g("pct_chr_digit")
  crc <- g("coerce_rate_strip")

  s <- c(
    composition  = clamp(dig),
    ## (-1,1) rescaled to (0,1): 0.5 means "parses exactly as much as its
    ## digit content suggests"; low means digit-heavy but non-numeric
    numeric_gap  = clamp(((if(is.na(crc)||is.na(dig)) NA_real_ else crc - dig) + 1) / 2),
    rigidity     = clamp(g("mask_top_share")),
    width        = clamp(log10(1 + g("len_mean")) / 2),
    punctuation  = clamp(g("pct_chr_punct")),
    tokenization = clamp(g("pct_single_tok")),
    cardinality  = clamp(g("unique_ratio"))
  )
  s
}

## ---------------------------------------------------------------------------
## fx_signature_distance() -- Gower-style: mean weighted absolute difference over
## the axes both signatures define. NA axes are dropped and the weights
## renormalized, so a column with no numeric content is not penalized for
## having no numeric axis.
## ---------------------------------------------------------------------------

#' Weighted distance between two type signatures
#'
#' A Gower-style weighted mean absolute difference over the axes both signatures
#' define. Axes that are `NA` in either signature are dropped and the weights
#' renormalized, so a column with no numeric content is not penalized for
#' lacking a numeric axis.
#'
#' @param a,b Signatures from [fx_type_signature()].
#' @param weights Per-axis weights (default [SIGNATURE_WEIGHTS]; see also
#'   [WEIGHTS_FORMAT]).
#' @param per_axis If `TRUE`, return the per-axis absolute differences instead
#'   of the aggregated distance.
#' @return A single distance in `[0,1]`, or a named per-axis vector.
#' @seealso [fx_type_signature()]
#' @export
fx_signature_distance <- function( a, b, weights = SIGNATURE_WEIGHTS, per_axis = FALSE ){
  ax <- names(SIGNATURE_AXES)
  w  <- weights[ax]; w[is.na(w)] <- 0
  d  <- abs(a[ax] - b[ax])
  ok <- !is.na(d) & w > 0
  if(!any(ok)) return(if(per_axis) setNames(rep(NA_real_, length(ax)), ax) else NA_real_)
  if(per_axis) return(d)
  sum(w[ok] * d[ok]) / sum(w[ok])
}

signature_similarity <- function(a, b, weights = SIGNATURE_WEIGHTS)
  1 - fx_signature_distance(a, b, weights)

## Pairwise distance matrix over a named list (or matrix of rows) of signatures.
signature_matrix <- function( sigs, weights = SIGNATURE_WEIGHTS ){
  if(is.list(sigs)) sigs <- do.call(rbind, sigs)
  n <- nrow(sigs); D <- matrix(NA_real_, n, n,
                               dimnames = list(rownames(sigs), rownames(sigs)))
  for(i in seq_len(n)) for(j in seq_len(n))
    D[i,j] <- if(i == j) 0 else fx_signature_distance(sigs[i,], sigs[j,], weights)
  D
}

## ---------------------------------------------------------------------------
## fx_path_distance() -- ontology distance on data_type/semantic_family/semantic_type.
##
## Format is deliberately NOT a level. Under the OR-wrapper design a detector
## fires if a value matches ANY registered format for its semantic_type, so
## confusing two formats of one semantic_type is a non-error, not a small
## error. Formats are variants inside a semantic_type, and the scoring unit is
## the semantic_type. This is what makes "model fit is by type, not by row"
## coherent.
##
## Distance = depth of the deepest shared ancestor, inverted and normalized.
##   same semantic_type (any format)      0.00
##   same semantic_family, diff type      0.33
##   same data_type, diff semantic_family 0.67
##   different data_type                  1.00
## ---------------------------------------------------------------------------

#' Taxonomic distance between two ontology paths
#'
#' Distance on the `data_type/semantic_family/semantic_type` path: the fraction
#' of levels that diverge once the shared prefix ends. Same leaf = 0; different
#' `data_type` = 1. Format is deliberately not a level.
#'
#' @param p1,p2 Slash-separated ontology paths.
#' @param levels Number of path levels to compare (default 3).
#' @return A distance in `[0,1]`.
#' @seealso [fx_signature_distance()], [fx_sibling_report()]
#' @export
fx_path_distance <- function( p1, p2, levels = 3 ){
  a <- strsplit(p1, "/", fixed = TRUE)[[1]][seq_len(levels)]
  b <- strsplit(p2, "/", fixed = TRUE)[[1]][seq_len(levels)]
  shared <- 0L
  for(i in seq_len(levels)){
    if(is.na(a[i]) || is.na(b[i]) || a[i] != b[i]) break
    shared <- i
  }
  (levels - shared) / levels
}

path_matrix <- function( paths, levels = 3 ){
  n <- length(paths)
  D <- matrix(0, n, n, dimnames = list(paths, paths))
  for(i in seq_len(n)) for(j in seq_len(n))
    D[i,j] <- fx_path_distance(paths[i], paths[j], levels)
  D
}

## ---------------------------------------------------------------------------
## fx_sibling_report() -- surfaces confusable pairs through both lenses and,
## importantly, flags where the two disagree.
##
##   ontology_sibling   near in the taxonomy      (fx_path_distance <= path_near)
##   signature_sibling  near in signature space   (sig_distance  <= sig_near)
##   status:
##     "both"          expected confusion, taxonomy and data agree
##     "hidden_risk"   FAR in taxonomy, NEAR in signature -- the dangerous set.
##                     These pairs need hard negatives banked against each
##                     other even though nothing in the ontology suggests it.
##     "safe_split"    NEAR in taxonomy, FAR in signature -- easy to tell
##                     apart despite being siblings. Cheap detectors suffice.
##     "unrelated"     far in both
##
## A semantic_type split that never produces a "safe_split" or "both" pairing --
## i.e. two semantic types whose signature distance is ~0 -- is a split the data
## cannot support, and under a guessability-based ontology it should collapse.
## ---------------------------------------------------------------------------

#' Surface confusable type pairs through the taxonomy and the data
#'
#' Compares every pair of types through two lenses -- taxonomic distance
#' ([fx_path_distance()]) and signature distance ([fx_signature_distance()]) --
#' and flags where they disagree. `hidden_risk` pairs (far in the taxonomy but
#' near in signature space) are the dangerous set that needs hard negatives
#' banked against each other; `safe_split` pairs are siblings the data tells
#' apart easily.
#'
#' @param sigs A named list (or matrix of rows) of signatures.
#' @param paths Ontology paths, aligned to `sigs`.
#' @param labels Row labels (default `names(paths)`).
#' @param weights Signature weights (default [SIGNATURE_WEIGHTS]).
#' @param path_near,sig_near Thresholds for taxonomic / signature nearness.
#' @return A data frame of pairs with distances and a `status` column
#'   (`both`, `hidden_risk`, `safe_split`, `unrelated`).
#' @seealso [fx_path_distance()], [fx_signature_distance()]
#' @export
fx_sibling_report <- function( sigs, paths, labels = names(paths),
                            weights = SIGNATURE_WEIGHTS,
                            path_near = 0.34, sig_near = 0.10 ){

  S <- signature_matrix(sigs, weights)
  P <- path_matrix(paths)
  n <- length(paths)
  idx <- which(upper.tri(matrix(0, n, n)), arr.ind = TRUE)

  out <- data.frame(
    a = labels[idx[,1]], b = labels[idx[,2]],
    path_dist = P[idx], sig_dist = round(S[idx], 3),
    stringsAsFactors = FALSE )
  out$ontology_sibling  <- out$path_dist <= path_near
  out$signature_sibling <- out$sig_dist  <= sig_near
  out$status <- with(out, ifelse( ontology_sibling &  signature_sibling, "both",
                          ifelse(!ontology_sibling &  signature_sibling, "hidden_risk",
                          ifelse( ontology_sibling & !signature_sibling, "safe_split",
                                  "unrelated"))))
  out[order(out$sig_dist), ]
}

## ---------------------------------------------------------------------------
## Which axis drives a given confusion? Useful when deciding what feature a
## detector needs in order to break a hidden_risk pair.
## ---------------------------------------------------------------------------

explain_pair <- function( sig_a, sig_b, weights = SIGNATURE_WEIGHTS ){
  d <- fx_signature_distance(sig_a, sig_b, weights, per_axis = TRUE)
  data.frame( axis = names(d), diff = round(as.numeric(d), 3),
              meaning = unname(SIGNATURE_AXES[names(d)]),
              stringsAsFactors = FALSE )[order(-d), ]
}
