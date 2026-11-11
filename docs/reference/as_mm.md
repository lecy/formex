# Format a value as a zero-padded two-digit month

Left-pads a month number to two digits (e.g. `8` becomes `"08"`). `NA`
is returned unchanged.

## Usage

``` r
as_mm(x)
```

## Arguments

- x:

  A single month value (numeric or character).

## Value

A 2-character month string, or `NA` if `x` is `NA`.

## See also

[`as_EIN()`](https://lecy.github.io/formex/reference/as_EIN.md),
[`as_yyyy()`](https://lecy.github.io/formex/reference/as_yyyy.md),
[`as_yyyymm()`](https://lecy.github.io/formex/reference/as_yyyymm.md)
