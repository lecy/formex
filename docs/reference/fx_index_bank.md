# Index a directory of banked test cases

Reads every `.json` case in a bank directory and returns one row per
case with its label, difficulty, ontology status, and profile size – the
flat view used to audit and sample the bank.

## Usage

``` r
fx_index_bank(dir = ".")
```

## Arguments

- dir:

  Bank directory (default the working directory).

## Value

A data frame, one row per case (empty if none). Requires `jsonlite`.

## See also

[`fx_bank_coverage()`](https://lecy.github.io/formex/reference/fx_bank_coverage.md),
[`fx_make_test_case()`](https://lecy.github.io/formex/reference/fx_make_test_case.md)
