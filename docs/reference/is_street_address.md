# Is it a street address?

Is it a street address?

## Usage

``` r
is_street_address(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `<number> <name> <street-type>`.

## See also

Other address detectors:
[`is_address()`](https://lecy.github.io/formex/reference/is_address.md),
[`is_city_name()`](https://lecy.github.io/formex/reference/is_city_name.md),
[`is_city_state()`](https://lecy.github.io/formex/reference/is_city_state.md),
[`is_po_box()`](https://lecy.github.io/formex/reference/is_po_box.md),
[`is_state_zip()`](https://lecy.github.io/formex/reference/is_state_zip.md)

## Examples

``` r
is_street_address(c("2325 140th St", "1225 S Walnut St", "Bloomington", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
