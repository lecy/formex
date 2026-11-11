# Is it an ISO 3166-1 country code?

Is it an ISO 3166-1 country code?

## Usage

``` r
is_country_code(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a valid alpha-2 country code (e.g. `US`).

## Details

Case-insensitive lookup against the internal `.iso3166_alpha2` table
(built by `data-raw/build_lookups.R` from the ISOcodes package). Note
this overlaps
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md)
for shared two-letter codes (e.g. `MT`);
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)'s
specificity ranking resolves such ties.

## See also

Other code detectors:
[`is_ca_postal_code()`](https://lecy.github.io/formex/reference/is_ca_postal_code.md),
[`is_http_status()`](https://lecy.github.io/formex/reference/is_http_status.md),
[`is_roman()`](https://lecy.github.io/formex/reference/is_roman.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_unix_time()`](https://lecy.github.io/formex/reference/is_unix_time.md),
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md),
[`is_zip_code()`](https://lecy.github.io/formex/reference/is_zip_code.md)

## Examples

``` r
is_country_code(c("US", "gb", "ZZ", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
