# Format a YYYYMM value as "YYYY-MM"

Splits a six-character `YYYYMM` value into a hyphenated `"YYYY-MM"`
string. `NA` is returned unchanged.

## Usage

``` r
as_yyyymm(x)
```

## Arguments

- x:

  A single `YYYYMM` value (numeric or character).

## Value

A `"YYYY-MM"` character string, or `NA` if `x` is `NA`.

## See also

[`as_yyyy()`](https://lecy.github.io/formex/reference/as_yyyy.md),
[`as_mm()`](https://lecy.github.io/formex/reference/as_mm.md)
