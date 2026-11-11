# Classify a single column under deployment rules (sample + gate + score)

The deployment entry point for one column. Draws a single row sample,
runs the block-gated feature extractor and the value/name detector over
it, and returns a prediction plus the feature row. This is the only
place that should call
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
in production, because it is the only place that guarantees the
extractor never runs un-sampled.

## Usage

``` r
fx_classify_column(
  x,
  name = NULL,
  n_rows = 500L,
  blocks = NULL,
  features_used = NULL,
  manifest = NULL,
  cardinality = c("full", "sample"),
  cascade = NULL,
  detectors = NULL,
  lexicons = default_lexicons(),
  threshold = 0.8,
  seed = 1L
)
```

## Arguments

- x:

  A column (any vector).

- name:

  Optional column header, used by the detector's name tie-break and the
  header feature block.

- n_rows:

  Row-sample size for the expensive feature blocks and detection. A few
  hundred is enough for format detection; see the package notes on the
  speed/coverage trade-off.

- blocks:

  Explicit feature blocks to compute; overrides `features_used`.

- features_used:

  Character vector of the feature names the fitted model references;
  blocks are derived from these via
  [`fx_feature_manifest()`](https://lecy.github.io/formex/reference/fx_feature_manifest.md).
  Ignored when `blocks` is supplied.

- manifest:

  Optional precomputed
  [`fx_feature_manifest()`](https://lecy.github.io/formex/reference/fx_feature_manifest.md)
  (pass it in a batch so it is not rebuilt per column).

- cardinality:

  `"full"` (default) recomputes the whole-column cardinality features
  (`n_unique`, `unique_ratio`, `hapax_ratio`, ...) with one extra linear
  pass, so those features are exact even though the string blocks were
  sampled. `"sample"` skips that pass entirely – fastest, but
  cardinality features then describe the sample, not the column.

- cascade:

  Optional scorer: a function of the one-row feature data frame
  returning a list with at least `guess`, `confidence`, and `ontology`.
  When `NULL`, falls back to the rule-based
  [`guess_column()`](https://lecy.github.io/formex/reference/guess_column.md).

- detectors:

  Named list of detector functions; pass the result of
  `data_type_detectors()` once in a batch to avoid re-resolving ~90
  functions per column. Ignored when `cascade` is supplied.

- lexicons:

  Lexicon set for the lexicon block; defaults to
  [`default_lexicons()`](https://lecy.github.io/formex/reference/default_lexicons.md).

- threshold:

  Minimum detector pass rate to trust a value guess.

- seed:

  Sampling seed (features and detection stay reproducible).

## Value

A list: `column`, `source`, `guess`, `confidence`, `ontology`,
`features` (one-row data frame), `blocks`, `n` (usable rows seen for
cardinality), `n_unique`, and `n_sampled`.

## See also

[`fx_classify_df()`](https://lecy.github.io/formex/reference/fx_classify_df.md),
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md),
[`guess_column()`](https://lecy.github.io/formex/reference/guess_column.md)
