# Confusion structure: what shape does "wrong" take?

Confusion structure: what shape does "wrong" take?

## Usage

``` r
fx_benchmark_confusion(
  res,
  level = c("data_type", "semantic_family", "semantic_type")
)
```

## Arguments

- res:

  Output of
  [`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md).

- level:

  Ontology level to tabulate (default `"data_type"`).

## Value

A list with `matrix` (gold x predicted counts at `level`), `wrong_shape`
(for each gold value, the distribution of the *wrong* predicted values,
as proportions), and `outcome` (the per-gold-data_type hit / graceful /
misroute mix, so graceful truncation is separated from a committed wrong
branch).

## See also

[`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md)
