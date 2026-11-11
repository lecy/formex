# Benchmark guess_data_type() over the frozen test library

Runs
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
on every column in `data`, times each call, and scores the predicted
`$route` against the gold label at every ontology level under
hierarchical partial credit (a level counts only if all its ancestors
match). `gold_style` / `gold_unit` are scored only where defined.

## Usage

``` r
fx_benchmark(
  data = fx_benchmark_data(),
  router = "auto",
  weights = .fx_level_weights(),
  max_n = 300L,
  progress = FALSE
)
```

## Arguments

- data:

  A benchmark data frame from
  [`fx_benchmark_data()`](https://lecy.github.io/formex/reference/fx_benchmark_data.md).

- router:

  Router strategy passed to
  [`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
  (`"auto"`, `"learned"`, `"signature"`).

- weights:

  Named partial-credit weights over the ontology levels.

- max_n:

  Cap on the reconstructed column length (speed guard).

- progress:

  If `TRUE`, print a progress dot every 50 cases.

## Value

A data frame, one row per case: the gold and predicted levels, the
per-level `*_correct` flags (`NA` where not scored), the `headline`
score, the `outcome` shape, `depth`, `confidence`, and `elapsed_sec`.

## See also

[`fx_benchmark_summary()`](https://lecy.github.io/formex/reference/fx_benchmark_summary.md),
[`fx_benchmark_confusion()`](https://lecy.github.io/formex/reference/fx_benchmark_confusion.md),
[`fx_coverage_gaps()`](https://lecy.github.io/formex/reference/fx_coverage_gaps.md),
[`fx_benchmark_compare()`](https://lecy.github.io/formex/reference/fx_benchmark_compare.md)
