# Is it a US ZIP code?

Is it a US ZIP code?

## Usage

``` r
is_zip_code(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `NNNNN` or `NNNNN-NNNN`.

## See also

Other code detectors:
[`is_ca_postal_code()`](https://lecy.github.io/formex/reference/is_ca_postal_code.md),
[`is_country_code()`](https://lecy.github.io/formex/reference/is_country_code.md),
[`is_http_status()`](https://lecy.github.io/formex/reference/is_http_status.md),
[`is_roman()`](https://lecy.github.io/formex/reference/is_roman.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_unix_time()`](https://lecy.github.io/formex/reference/is_unix_time.md),
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md)

## Examples

``` r
is_zip_code(c("98052", "98052-6399", "1234", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
