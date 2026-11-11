# Is it a US Employer Identification Number (EIN)?

Nine digits, written `NN-NNNNNNN` or as plain digits. The two-digit
prefix is the assigning IRS campus code; `00` is never issued, so it
(and degenerate all-same values) is rejected. A bare 9-digit number is
still weakly specific – the variable-name hint is the real
disambiguator, so `is_ein` is marked loose in the ontology. (A fuller
valid-prefix whitelist would raise specificity; it needs the fixture
generator updated in lockstep.)

## Usage

``` r
is_ein(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a plausible EIN.

## See also

Other gov detectors:
[`is_chinese_resident_id()`](https://lecy.github.io/formex/reference/is_chinese_resident_id.md),
[`is_dea()`](https://lecy.github.io/formex/reference/is_dea.md),
[`is_naics()`](https://lecy.github.io/formex/reference/is_naics.md),
[`is_ssn()`](https://lecy.github.io/formex/reference/is_ssn.md),
[`is_uei()`](https://lecy.github.io/formex/reference/is_uei.md)

## Examples

``` r
is_ein(c("15-4464349", "154464349", "00-1234567", "111111111", NA))
#> [1]  TRUE  TRUE FALSE FALSE    NA
```
