# Compare two benchmark runs (track progress over time)

Compare two benchmark runs (track progress over time)

## Usage

``` r
fx_benchmark_compare(old, new)
```

## Arguments

- old, new:

  Outputs of
  [`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md)
  (e.g. before/after a change).

## Value

A list with `overall` (per-level accuracy and headline deltas, new minus
old) and `by_data_type` (per gold data_type, the type-accuracy delta),
with regressions (negative deltas) sorted first.

## See also

[`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md),
[`fx_benchmark_summary()`](https://lecy.github.io/formex/reference/fx_benchmark_summary.md)
