# Is it a US state abbreviation?

Is it a US state abbreviation?

## Usage

``` r
is_us_state(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a USPS two-letter state code (plus `DC`).

## See also

Other code detectors:
[`is_ca_postal_code()`](https://lecy.github.io/formex/reference/is_ca_postal_code.md),
[`is_country_code()`](https://lecy.github.io/formex/reference/is_country_code.md),
[`is_http_status()`](https://lecy.github.io/formex/reference/is_http_status.md),
[`is_roman()`](https://lecy.github.io/formex/reference/is_roman.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_unix_time()`](https://lecy.github.io/formex/reference/is_unix_time.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md),
[`is_zip_code()`](https://lecy.github.io/formex/reference/is_zip_code.md)

## Examples

``` r
is_us_state(c("WA", "dc", "ZZ", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
