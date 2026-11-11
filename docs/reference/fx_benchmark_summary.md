# Summarize a benchmark run

Summarize a benchmark run

## Usage

``` r
fx_benchmark_summary(res, by_tier = TRUE)
```

## Arguments

- res:

  Output of
  [`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md).

- by_tier:

  If `TRUE`, also break the per-level accuracy out by `tier`.

## Value

A list with `overall` (per-level accuracy, mean headline, prediction
coverage, and the hit/graceful/misroute mix), `by_data_type` (per gold
data_type: support, type accuracy, headline), `runtime` (total / mean /
median / p95 seconds per case), and, when `by_tier`, a `by_tier` table.

## See also

[`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md)
