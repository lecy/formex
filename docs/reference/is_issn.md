# Is it an ISSN?

Is it an ISSN?

## Usage

``` r
is_issn(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `dddd-dddC` with a valid mod-11 check digit
(`C` may be `X`).

## See also

Other research-id detectors:
[`is_doi()`](https://lecy.github.io/formex/reference/is_doi.md),
[`is_isbn()`](https://lecy.github.io/formex/reference/is_isbn.md),
[`is_npi()`](https://lecy.github.io/formex/reference/is_npi.md),
[`is_orcid()`](https://lecy.github.io/formex/reference/is_orcid.md)

## Examples

``` r
is_issn(c("0003-021X", "0161-9268", "0003-0210", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
