# Is it a version identifier?

Tests whether each element is a dotted version string, optionally
`v`-prefixed and with a pre-release/build suffix: `"1.4.0"`, `"v2"`,
`"2.10.3"`, `"v1.0"`, `"3.2.1-rc1"`. A bare integer is not a version
(that is a count/id); at least one dotted component or a `v` prefix is
required.

## Usage

``` r
is_version(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector; `TRUE` for a version string, `FALSE` otherwise, `NA`
where `x` is `NA`.

## See also

[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other code detectors:
[`is_ca_postal_code()`](https://lecy.github.io/formex/reference/is_ca_postal_code.md),
[`is_country_code()`](https://lecy.github.io/formex/reference/is_country_code.md),
[`is_http_status()`](https://lecy.github.io/formex/reference/is_http_status.md),
[`is_roman()`](https://lecy.github.io/formex/reference/is_roman.md),
[`is_uk_postcode()`](https://lecy.github.io/formex/reference/is_uk_postcode.md),
[`is_unix_time()`](https://lecy.github.io/formex/reference/is_unix_time.md),
[`is_us_state()`](https://lecy.github.io/formex/reference/is_us_state.md),
[`is_zip_code()`](https://lecy.github.io/formex/reference/is_zip_code.md)

## Examples

``` r
is_version(c("1.4.0", "v2", "2019", "banana", NA))
#> [1]  TRUE  TRUE FALSE FALSE    NA
#> TRUE TRUE FALSE FALSE NA
```
