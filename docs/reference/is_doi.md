# Is it a DOI?

Is it a DOI?

## Usage

``` r
is_doi(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a `10.<registrant>/<suffix>` DOI.

## See also

Other research-id detectors:
[`is_isbn()`](https://lecy.github.io/formex/reference/is_isbn.md),
[`is_issn()`](https://lecy.github.io/formex/reference/is_issn.md),
[`is_npi()`](https://lecy.github.io/formex/reference/is_npi.md),
[`is_orcid()`](https://lecy.github.io/formex/reference/is_orcid.md)

## Examples

``` r
is_doi(c("10.1109/ICDCSW.2017.43", "not-a-doi", NA))
#> [1]  TRUE FALSE    NA
```
