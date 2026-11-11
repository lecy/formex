# Is it a state FIPS code?

Is it a state FIPS code?

## Usage

``` r
is_state_fips(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a valid 2-digit state/territory FIPS.

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
[`is_tract_fips()`](https://lecy.github.io/formex/reference/is_tract_fips.md),
[`is_urban_rural()`](https://lecy.github.io/formex/reference/is_urban_rural.md)

## Examples

``` r
is_state_fips(c("06", "36", "03", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
