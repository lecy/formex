# Is it an HTTP status code?

Is it an HTTP status code?

## Usage

``` r
is_http_status(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a three-digit code in 100-599.

## See also

Other code detectors:
[`is_ca_postal_code()`](https://lecy.github.io/formex/reference/is_ca_postal_code.md),
[`is_country_code()`](https://lecy.github.io/formex/reference/is_country_code.md),
[`is_roman()`](https://lecy.github.io/formex/reference/is_roman.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_unix_time()`](https://lecy.github.io/formex/reference/is_unix_time.md),
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md),
[`is_zip_code()`](https://lecy.github.io/formex/reference/is_zip_code.md)

## Examples

``` r
is_http_status(c("200", "404", "099", "600", NA))
#> [1]  TRUE  TRUE FALSE FALSE    NA
```
