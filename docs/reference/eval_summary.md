# Summarize an evaluation into overall and per-class metrics

Summarize an evaluation into overall and per-class metrics

## Usage

``` r
eval_summary(results)
```

## Arguments

- results:

  Output of
  [`evaluate_columns()`](https://lecy.github.io/formex/reference/evaluate_columns.md).

## Value

A list with `overall` (a one-row data frame: column counts, class and
type accuracy over in-scope columns, and prediction coverage) and
`by_class` (per gold class: `support`, `recall`, `precision`, `f1`).
Precision is computed over ALL predictions of a class (in- and
out-of-scope columns), so a detector firing on out-of-scope columns is
penalized.

## See also

[`evaluate_columns()`](https://lecy.github.io/formex/reference/evaluate_columns.md)
