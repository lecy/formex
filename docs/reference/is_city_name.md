# Is it a US city / place name?

Is it a US city / place name?

## Usage

``` r
is_city_name(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a name in the normalized `.us_cities` lookup
(case/punctuation-insensitive). Coverage is the ~1,000 larger US cities
(maps::us.cities); smaller towns will miss.

## See also

Other address detectors:
[`is_address()`](https://lecy.github.io/formex/reference/is_address.md),
[`is_city_state()`](https://lecy.github.io/formex/reference/is_city_state.md),
[`is_po_box()`](https://lecy.github.io/formex/reference/is_po_box.md),
[`is_state_zip()`](https://lecy.github.io/formex/reference/is_state_zip.md),
[`is_street_address()`](https://lecy.github.io/formex/reference/is_street_address.md)

## Examples

``` r
is_city_name(c("Chicago", "New Orleans", "Nowheresville", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
