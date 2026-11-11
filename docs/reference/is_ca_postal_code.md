# Is it a Canadian postal code (or FSA)?

Is it a Canadian postal code (or FSA)?

## Usage

``` r
is_ca_postal_code(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 3-char FSA (`V5K`) or full `A1A 1A1`.

## See also

Other code detectors:
[`is_country_code()`](https://lecy.github.io/formex/reference/is_country_code.md),
[`is_http_status()`](https://lecy.github.io/formex/reference/is_http_status.md),
[`is_roman()`](https://lecy.github.io/formex/reference/is_roman.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_unix_time()`](https://lecy.github.io/formex/reference/is_unix_time.md),
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md),
[`is_zip_code()`](https://lecy.github.io/formex/reference/is_zip_code.md)

## Examples

``` r
is_ca_postal_code(c("V5K", "K1A 0B1", "12345", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
