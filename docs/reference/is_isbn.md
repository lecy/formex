# Is it an ISBN (10 or 13)?

Is it an ISBN (10 or 13)?

## Usage

``` r
is_isbn(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a valid ISBN-10 or ISBN-13 (dashes/spaces
ignored) whose check digit is correct.

## See also

Other research-id detectors:
[`is_doi()`](https://lecy.github.io/formex/reference/is_doi.md),
[`is_issn()`](https://lecy.github.io/formex/reference/is_issn.md),
[`is_npi()`](https://lecy.github.io/formex/reference/is_npi.md),
[`is_orcid()`](https://lecy.github.io/formex/reference/is_orcid.md)

## Examples

``` r
is_isbn(c("140955525-9", "978-3-16-148410-0", "140955525-8", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
