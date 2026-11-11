# Contamination breaking-point curve

Contamination breaking-point curve

## Usage

``` r
fx_contamination_curve(grid)
```

## Arguments

- grid:

  Output of
  [`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md)
  run with `contamination_sweep = TRUE`.

## Value

A data frame of mixing fraction vs. type accuracy (and headline),
including the clean (0%) baseline, ordered by fraction – the point where
accuracy crosses ~0.5 is the empirical breaking point.

## See also

[`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md)
