# Is it a NAICS industry code?

Is it a NAICS industry code?

## Usage

``` r
is_naics(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 2-6 digit code present in the NAICS code
list at any level (`.naics`, rolled up from the 2022 NAICS index).

## See also

Other gov detectors:
[`is_chinese_resident_id()`](https://lecy.github.io/formex/reference/is_chinese_resident_id.md),
[`is_dea()`](https://lecy.github.io/formex/reference/is_dea.md),
[`is_ein()`](https://lecy.github.io/formex/reference/is_ein.md),
[`is_ssn()`](https://lecy.github.io/formex/reference/is_ssn.md),
[`is_uei()`](https://lecy.github.io/formex/reference/is_uei.md)

## Examples

``` r
is_naics(c("11", "541511", "99", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
