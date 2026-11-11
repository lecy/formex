# Is it a Roman numeral?

Is it a Roman numeral?

## Usage

``` r
is_roman(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a well-formed uppercase Roman numeral.

## See also

Other code detectors:
[`is_ca_postal_code()`](https://lecy.github.io/formex/reference/is_ca_postal_code.md),
[`is_country_code()`](https://lecy.github.io/formex/reference/is_country_code.md),
[`is_http_status()`](https://lecy.github.io/formex/reference/is_http_status.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_unix_time()`](https://lecy.github.io/formex/reference/is_unix_time.md),
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md),
[`is_zip_code()`](https://lecy.github.io/formex/reference/is_zip_code.md)

## Examples

``` r
is_roman(c("XIV", "MMXXIV", "IIII", "", NA))
#> [1]  TRUE  TRUE FALSE FALSE    NA
```
