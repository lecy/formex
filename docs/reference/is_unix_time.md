# Is it a Unix timestamp (seconds)?

Is it a Unix timestamp (seconds)?

## Usage

``` r
is_unix_time(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 9-10 digit epoch-seconds value.

## Details

Inherently loose: any 9-10 digit integer in the plausible epoch range
matches. Intended as a weak signal, corrected in the DGF if wrong.

## See also

Other code detectors:
[`is_ca_postal_code()`](https://lecy.github.io/formex/reference/is_ca_postal_code.md),
[`is_country_code()`](https://lecy.github.io/formex/reference/is_country_code.md),
[`is_http_status()`](https://lecy.github.io/formex/reference/is_http_status.md),
[`is_roman()`](https://lecy.github.io/formex/reference/is_roman.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md),
[`is_zip_code()`](https://lecy.github.io/formex/reference/is_zip_code.md)

## Examples

``` r
is_unix_time(c("1513036980", "946684800", "12345", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
