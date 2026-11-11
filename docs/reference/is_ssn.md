# Is it a US Social Security Number?

Is it a US Social Security Number?

## Usage

``` r
is_ssn(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `ddd-dd-dddd` passing SSN issuance rules
(area not 000/666/900-999, group not 00, serial not 0000).

## See also

Other gov detectors:
[`is_chinese_resident_id()`](https://lecy.github.io/formex/reference/is_chinese_resident_id.md),
[`is_dea()`](https://lecy.github.io/formex/reference/is_dea.md),
[`is_ein()`](https://lecy.github.io/formex/reference/is_ein.md),
[`is_naics()`](https://lecy.github.io/formex/reference/is_naics.md),
[`is_uei()`](https://lecy.github.io/formex/reference/is_uei.md)

## Examples

``` r
is_ssn(c("540-39-4268", "000-12-3456", NA))
#> [1]  TRUE FALSE    NA
```
