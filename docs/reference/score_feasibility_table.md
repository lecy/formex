# Score a table of predictions against a feasibility crosswalk

Score a table of predictions against a feasibility crosswalk

## Usage

``` r
score_feasibility_table(preds, crosswalk)
```

## Arguments

- preds:

  A data frame with `type`, `class`, `subclass` columns (predicted; `NA`
  for unreached levels), optionally `unit`, and a `key` column linking
  to the crosswalk (defaults to matching by row order).

- crosswalk:

  A data frame with `v4_type`, `v4_class`, `v4_subclass`,
  `feasible_depth`, optional `unit`, one row per prediction (same
  order).

## Value

`preds` with `score` and `unit_recovered` columns added.

## See also

[`feasibility_score()`](https://lecy.github.io/formex/reference/feasibility_score.md)
