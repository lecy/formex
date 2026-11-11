# Summarize the stress grid: accuracy decay per dimension and level

Summarize the stress grid: accuracy decay per dimension and level

## Usage

``` r
fx_stress_summary(grid)
```

## Arguments

- grid:

  Output of
  [`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md).

## Value

A list with `by_level` (per dimension x level: type accuracy, headline,
the hit/graceful/misroute mix, and `delta_type` / `delta_headline`
versus the shared clean baseline) and `by_type` (per gold data_type x
dimension x level: type accuracy and its delta from clean), both ordered
to surface the largest drops first. Only `applicable` rows are counted.

## See also

[`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md)
