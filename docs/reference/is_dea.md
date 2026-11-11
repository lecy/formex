# Is it a DEA registration number?

Is it a DEA registration number?

## Usage

``` r
is_dea(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for two letters + seven digits whose DEA check
digit is valid.

## See also

Other gov detectors:
[`is_chinese_resident_id()`](https://lecy.github.io/formex/reference/is_chinese_resident_id.md),
[`is_ein()`](https://lecy.github.io/formex/reference/is_ein.md),
[`is_naics()`](https://lecy.github.io/formex/reference/is_naics.md),
[`is_ssn()`](https://lecy.github.io/formex/reference/is_ssn.md),
[`is_uei()`](https://lecy.github.io/formex/reference/is_uei.md)

## Examples

``` r
is_dea(c("AP5836727", "AP5836728", NA))
#> [1]  TRUE FALSE    NA
```
