# Is it an urban/rural designation?

Is it an urban/rural designation?

## Usage

``` r
is_urban_rural(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for common urban/rural designation words.

## See also

Other geography detectors:
[`is_block_fips()`](https://lecy.github.io/formex/reference/is_block_fips.md),
[`is_block_group_fips()`](https://lecy.github.io/formex/reference/is_block_group_fips.md),
[`is_cbsa()`](https://lecy.github.io/formex/reference/is_cbsa.md),
[`is_census_region()`](https://lecy.github.io/formex/reference/is_census_region.md),
[`is_county_fips()`](https://lecy.github.io/formex/reference/is_county_fips.md),
[`is_csa()`](https://lecy.github.io/formex/reference/is_csa.md),
[`is_metro_area_name()`](https://lecy.github.io/formex/reference/is_metro_area_name.md),
[`is_nces_locale()`](https://lecy.github.io/formex/reference/is_nces_locale.md),
[`is_state_fips()`](https://lecy.github.io/formex/reference/is_state_fips.md),
[`is_tract_fips()`](https://lecy.github.io/formex/reference/is_tract_fips.md)

## Examples

``` r
is_urban_rural(c("Urban", "rural", "Suburban", "banana", NA))
#> [1]  TRUE  TRUE  TRUE FALSE    NA
```
