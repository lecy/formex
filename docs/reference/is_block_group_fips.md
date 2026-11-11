# Is it a census block-group FIPS code?

Is it a census block-group FIPS code?

## Usage

``` r
is_block_group_fips(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 12-digit code with a valid state prefix.

## See also

Other geography detectors:
[`is_block_fips()`](https://lecy.github.io/formex/reference/is_block_fips.md),
[`is_cbsa()`](https://lecy.github.io/formex/reference/is_cbsa.md),
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
is_block_group_fips(c("060372062001", NA))
#> [1] TRUE   NA
```
