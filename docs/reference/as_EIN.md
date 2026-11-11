# Format a value as a canonical hyphenated EIN

Normalizes an Employer Identification Number to the canonical
`"NN-NNNNNNN"` form, restoring a leading zero lost to numeric coercion.
`NA` is returned unchanged.

## Usage

``` r
as_EIN(x)
```

## Arguments

- x:

  A single EIN value (numeric or character).

## Value

A canonical EIN string `"NN-NNNNNNN"`, or `NA` if `x` is `NA`. Any
non-digits (a prefix, an existing hyphen) are stripped first, and an
8-digit value (a leading zero lost to numeric coercion) is zero-padded
back to nine before the hyphen is inserted.

## See also

[`as_mm()`](https://lecy.github.io/formex/reference/as_mm.md),
[`as_yyyy()`](https://lecy.github.io/formex/reference/as_yyyy.md),
[`as_yyyymm()`](https://lecy.github.io/formex/reference/as_yyyymm.md)
