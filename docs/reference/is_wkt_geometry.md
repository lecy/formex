# Is it a WKT (Well-Known Text) geometry?

Is it a WKT (Well-Known Text) geometry?

## Usage

``` r
is_wkt_geometry(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a WKT geometry literal such as
`POINT (30 10)` or `POLYGON ((...))`, optionally with a `Z`/`M`/`ZM`
dimensionality tag. Matches the standard OGC geometry types.

## See also

Other geometry detectors:
[`is_geojson()`](https://lecy.github.io/formex/reference/is_geojson.md),
[`is_wkb()`](https://lecy.github.io/formex/reference/is_wkb.md)

## Examples

``` r
is_wkt_geometry(c("POINT (30 10)", "LINESTRING (0 0, 1 1)", "banana", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
