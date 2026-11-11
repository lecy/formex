# Is it a metropolitan-area name?

Is it a metropolitan-area name?

## Usage

``` r
is_metro_area_name(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a CBSA or CSA title (e.g.
`"New York-Newark-Jersey City, NY-NJ-PA"`), matched case-insensitively
against the `.metro_area_names` lookup. The lookup stores both the full
title and a state-suffix-stripped variant, so `"Corpus Christi, TX"` and
`"Corpus Christi"` both match.

## Details

Exact-match on official Census titles; free-form metro names
(`"NYC metro"`) will miss. Distinct from
[`is_city_name()`](https://lecy.github.io/formex/reference/is_city_name.md),
which won't match these hyphenated multi-city titles.

## See also

Other geography detectors:
[`is_block_fips()`](https://lecy.github.io/formex/reference/is_block_fips.md),
[`is_block_group_fips()`](https://lecy.github.io/formex/reference/is_block_group_fips.md),
[`is_cbsa()`](https://lecy.github.io/formex/reference/is_cbsa.md),
[`is_census_region()`](https://lecy.github.io/formex/reference/is_census_region.md),
[`is_county_fips()`](https://lecy.github.io/formex/reference/is_county_fips.md),
[`is_csa()`](https://lecy.github.io/formex/reference/is_csa.md),
[`is_nces_locale()`](https://lecy.github.io/formex/reference/is_nces_locale.md),
[`is_state_fips()`](https://lecy.github.io/formex/reference/is_state_fips.md),
[`is_tract_fips()`](https://lecy.github.io/formex/reference/is_tract_fips.md),
[`is_urban_rural()`](https://lecy.github.io/formex/reference/is_urban_rural.md)

## Examples

``` r
is_metro_area_name(c("Abilene-Sweetwater, TX", "Chicago", NA))
#> [1]  TRUE FALSE    NA
```
