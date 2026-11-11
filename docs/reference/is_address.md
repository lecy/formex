# Is it a full postal address?

Scans each string for address components (street, PO box, city, state,
ZIP) and returns `TRUE` when at least `min_flags` of them are present. A
single component (just a ZIP, just a city) scores 1 and is better
handled by the atomic detector; a full address scores 3-5.

## Usage

``` r
is_address(x, min_flags = 3)
```

## Arguments

- x:

  A character vector.

- min_flags:

  Minimum number of distinct components required (default 3).

## Value

Logical vector; `TRUE` where `>= min_flags` components co-occur.

## See also

Other address detectors:
[`is_city_name()`](https://lecy.github.io/formex/reference/is_city_name.md),
[`is_city_state()`](https://lecy.github.io/formex/reference/is_city_state.md),
[`is_po_box()`](https://lecy.github.io/formex/reference/is_po_box.md),
[`is_state_zip()`](https://lecy.github.io/formex/reference/is_state_zip.md),
[`is_street_address()`](https://lecy.github.io/formex/reference/is_street_address.md)

## Examples

``` r
is_address(c("1225 S Walnut St, Bloomington, IN 47401", "Chicago", NA))
#> [1]  TRUE FALSE    NA
```
