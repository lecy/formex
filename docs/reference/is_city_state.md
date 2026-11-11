# Is it a "City, State" value?

Is it a "City, State" value?

## Usage

``` r
is_city_state(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `<anything>, <state abbrev or name>`.

## See also

Other address detectors:
[`is_address()`](https://lecy.github.io/formex/reference/is_address.md),
[`is_city_name()`](https://lecy.github.io/formex/reference/is_city_name.md),
[`is_po_box()`](https://lecy.github.io/formex/reference/is_po_box.md),
[`is_state_zip()`](https://lecy.github.io/formex/reference/is_state_zip.md),
[`is_street_address()`](https://lecy.github.io/formex/reference/is_street_address.md)

## Examples

``` r
is_city_state(c("Bloomington, IN", "Bloomington, Indiana", "just text", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
