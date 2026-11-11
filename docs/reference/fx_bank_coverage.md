# Coverage of a test-case bank by type and difficulty

Cross-tabulates the banked cases by `semantic_type` and difficulty
(easy/medium/hard), so gaps in the regression corpus are visible at a
glance.

## Usage

``` r
fx_bank_coverage(dir = ".")
```

## Arguments

- dir:

  Bank directory (default the working directory).

## Value

A data frame of counts per semantic_type x difficulty.

## See also

[`fx_index_bank()`](https://lecy.github.io/formex/reference/fx_index_bank.md)
