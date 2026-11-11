# Is it an NCES locale code?

Is it an NCES locale code?

## Usage

``` r
is_nces_locale(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 2-digit NCES locale code (11-13, 21-23,
31-33, 41-43 = City/Suburb/Town/Rural x Large/Midsize/Small).

## See also

Other geography detectors:
[`is_block_fips()`](https://lecy.github.io/formex/reference/is_block_fips.md),
[`is_block_group_fips()`](https://lecy.github.io/formex/reference/is_block_group_fips.md),
[`is_cbsa()`](https://lecy.github.io/formex/reference/is_cbsa.md),
[`is_census_region()`](https://lecy.github.io/formex/reference/is_census_region.md),
[`is_county_fips()`](https://lecy.github.io/formex/reference/is_county_fips.md),
[`is_csa()`](https://lecy.github.io/formex/reference/is_csa.md),
[`is_metro_area_name()`](https://lecy.github.io/formex/reference/is_metro_area_name.md),
[`is_state_fips()`](https://lecy.github.io/formex/reference/is_state_fips.md),
[`is_tract_fips()`](https://lecy.github.io/formex/reference/is_tract_fips.md),
[`is_urban_rural()`](https://lecy.github.io/formex/reference/is_urban_rural.md)

## Examples

``` r
is_nces_locale(c("11", "23", "44", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
