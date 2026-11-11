# Is it an ORCID iD?

Is it an ORCID iD?

## Usage

``` r
is_orcid(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a `dddd-dddd-dddd-dddC` ORCID whose ISO 7064
mod-11-2 check digit is valid (`C` may be `X`).

## See also

Other research-id detectors:
[`is_doi()`](https://lecy.github.io/formex/reference/is_doi.md),
[`is_isbn()`](https://lecy.github.io/formex/reference/is_isbn.md),
[`is_issn()`](https://lecy.github.io/formex/reference/is_issn.md),
[`is_npi()`](https://lecy.github.io/formex/reference/is_npi.md)

## Examples

``` r
is_orcid(c("0000-0002-0488-8591", "0000-0002-0488-8590", NA))
#> [1]  TRUE FALSE    NA
```
