# Evaluate formex predictions against a labeled column corpus

Evaluate formex predictions against a labeled column corpus

## Usage

``` r
evaluate_columns(
  columns,
  labels,
  crosswalk,
  headers = NULL,
  use_name = FALSE,
  ...
)
```

## Arguments

- columns:

  A list of character vectors, one per labeled column.

- labels:

  A character vector of source-vocabulary labels,
  `length == length(columns)`.

- crosswalk:

  A data frame with columns `source_label`, `data_type`, `data_subtype`,
  `data_class` mapping each source label to a formex triple
  (`data_class = NA` marks an out-of-scope label).

- headers:

  Optional character vector of real column headers (only used when
  `use_name = TRUE`).

- use_name:

  If `TRUE`, predict with
  [`guess_column()`](https://lecy.github.io/formex/reference/guess_column.md)
  (values + name); otherwise value-only via
  [`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md).

- ...:

  Passed to the underlying guesser (e.g. `threshold`, `n_sample`).

## Value

A data frame with one row per column: `label`, `gold_type`,
`gold_class`, `pred_detector`, `pred_type`, `pred_class`, `source`,
`in_scope`, `class_correct`, `type_correct`.

## See also

[`eval_summary()`](https://lecy.github.io/formex/reference/eval_summary.md)
