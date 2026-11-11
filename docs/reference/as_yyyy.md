# Format a value as a four-digit year

Coerces a year to character, warning if it has more than four digits.
`NA` is returned unchanged.

## Usage

``` r
as_yyyy(x)
```

## Arguments

- x:

  A single year value (numeric or character).

## Value

The four-digit year as a character string, or `NA` if `x` is `NA`.

## Details

A fiscal-year prefix (`"FY2019"`, `"FY 2019"`) is stripped and the
embedded four-digit year returned. A value that already is a four-digit
year passes through; anything else warns and is returned unchanged.

## See also

[`as_mm()`](https://lecy.github.io/formex/reference/as_mm.md),
[`as_yyyymm()`](https://lecy.github.io/formex/reference/as_yyyymm.md)
