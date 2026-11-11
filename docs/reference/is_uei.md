# Is it a SAM.gov Unique Entity Identifier (UEI)?

Is it a SAM.gov Unique Entity Identifier (UEI)?

## Usage

``` r
is_uei(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 12-character alphanumeric UEI (no letters
`I`/`O`, first character not `0`).

## See also

Other gov detectors:
[`is_chinese_resident_id()`](https://lecy.github.io/formex/reference/is_chinese_resident_id.md),
[`is_dea()`](https://lecy.github.io/formex/reference/is_dea.md),
[`is_ein()`](https://lecy.github.io/formex/reference/is_ein.md),
[`is_naics()`](https://lecy.github.io/formex/reference/is_naics.md),
[`is_ssn()`](https://lecy.github.io/formex/reference/is_ssn.md)

## Examples

``` r
is_uei(c("ABC123DEF456", "O1234567890X", NA))
#> [1]  TRUE FALSE    NA
```
