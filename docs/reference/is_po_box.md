# Is it a PO box?

Is it a PO box?

## Usage

``` r
is_po_box(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for PO box variants (`PO Box 12`, `P.O.B. 3`).

## See also

Other address detectors:
[`is_address()`](https://lecy.github.io/formex/reference/is_address.md),
[`is_city_name()`](https://lecy.github.io/formex/reference/is_city_name.md),
[`is_city_state()`](https://lecy.github.io/formex/reference/is_city_state.md),
[`is_state_zip()`](https://lecy.github.io/formex/reference/is_state_zip.md),
[`is_street_address()`](https://lecy.github.io/formex/reference/is_street_address.md)

## Examples

``` r
is_po_box(c("PO Box 1234", "P.O. Box 56", "POB 789", NA))
#> [1] TRUE TRUE TRUE   NA
```
