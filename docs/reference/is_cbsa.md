# Is it a CBSA code?

Is it a CBSA code?

## Usage

``` r
is_cbsa(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 5-digit Core Based Statistical Area code in
the Census delineation (`.cbsa` lookup).

## See also

Other geography detectors:
[`is_block_fips()`](https://lecy.github.io/formex/reference/is_block_fips.md),
[`is_block_group_fips()`](https://lecy.github.io/formex/reference/is_block_group_fips.md),
[`is_census_region()`](https://lecy.github.io/formex/reference/is_census_region.md),
[`is_county_fips()`](https://lecy.github.io/formex/reference/is_county_fips.md),
[`is_csa()`](https://lecy.github.io/formex/reference/is_csa.md),
[`is_metro_area_name()`](https://lecy.github.io/formex/reference/is_metro_area_name.md),
[`is_nces_locale()`](https://lecy.github.io/formex/reference/is_nces_locale.md),
[`is_state_fips()`](https://lecy.github.io/formex/reference/is_state_fips.md),
[`is_tract_fips()`](https://lecy.github.io/formex/reference/is_tract_fips.md),
[`is_urban_rural()`](https://lecy.github.io/formex/reference/is_urban_rural.md)

## Examples

``` r
is_cbsa(c("10180", "35620", "99999", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
