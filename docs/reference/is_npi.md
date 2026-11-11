# Is it an NPI (US health provider)?

Is it an NPI (US health provider)?

## Usage

``` r
is_npi(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 10-digit NPI whose Luhn check digit (over
the `80840` prefix + first 9 digits) is valid.

## See also

Other research-id detectors:
[`is_doi()`](https://lecy.github.io/formex/reference/is_doi.md),
[`is_isbn()`](https://lecy.github.io/formex/reference/is_isbn.md),
[`is_issn()`](https://lecy.github.io/formex/reference/is_issn.md),
[`is_orcid()`](https://lecy.github.io/formex/reference/is_orcid.md)

## Examples

``` r
is_npi(c("1225155880", "1234567890", NA))
#> [1]  TRUE FALSE    NA
```
