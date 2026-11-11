# Is it a "State ZIP" value?

Is it a "State ZIP" value?

## Usage

``` r
is_state_zip(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `<state abbrev or name>[,] <ZIP>`.

## See also

Other address detectors:
[`is_address()`](https://lecy.github.io/formex/reference/is_address.md),
[`is_city_name()`](https://lecy.github.io/formex/reference/is_city_name.md),
[`is_city_state()`](https://lecy.github.io/formex/reference/is_city_state.md),
[`is_po_box()`](https://lecy.github.io/formex/reference/is_po_box.md),
[`is_street_address()`](https://lecy.github.io/formex/reference/is_street_address.md)

## Examples

``` r
is_state_zip(c("IN 47401", "Indiana 47401", "CA, 90210", NA))
#> [1] TRUE TRUE TRUE   NA
```
