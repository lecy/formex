# Classify every column of a data frame under deployment rules

Batch driver over
[`fx_classify_column()`](https://lecy.github.io/formex/reference/fx_classify_column.md).
Resolves the detector list (or the feature manifest) ONCE and reuses it
across columns, then returns a tidy one-row-per-column prediction table.
Feature rows are attached as an attribute (`"features"`) for callers
that want them.

## Usage

``` r
fx_classify_df(
  df,
  cols = names(df),
  n_rows = 500L,
  blocks = NULL,
  features_used = NULL,
  cardinality = c("full", "sample"),
  cascade = NULL,
  lexicons = default_lexicons(),
  threshold = 0.8,
  seed = 1L
)
```

## Arguments

- df:

  A data frame (or list of columns).

- cols:

  Which columns to classify; defaults to all.

- n_rows, blocks, features_used, cardinality, cascade, lexicons,
  threshold, seed:

  Passed through to
  [`fx_classify_column()`](https://lecy.github.io/formex/reference/fx_classify_column.md).

## Value

A data frame with `column`, `source`, `guess`, `confidence`,
`data_type`, `data_class`, `n`, `n_unique`, `n_sampled`. The per-column
feature rows are bound into a data frame stored in
`attr(., "features")`.

## See also

[`fx_classify_column()`](https://lecy.github.io/formex/reference/fx_classify_column.md)
