# Is it Well-Known Binary (WKB / EWKB) geometry?

Is it Well-Known Binary (WKB / EWKB) geometry?

## Usage

``` r
is_wkb(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a hex-encoded WKB string: an even-length hex
value opening with a byte-order flag (`00` big-endian / `01`
little-endian) whose 4-byte geometry-type field decodes to a base OGC
type (1-7), tolerating ISO Z/M (`+1000/2000/3000`) and EWKB SRID/Z/M
high-bit flags. The type check is what separates a real WKB blob from an
arbitrary hex digest of the same length.

## See also

Other geometry detectors:
[`is_geojson()`](https://lecy.github.io/formex/reference/is_geojson.md),
[`is_wkt_geometry()`](https://lecy.github.io/formex/reference/is_wkt_geometry.md)

## Examples

``` r
is_wkb(c("0101000000000000000000f03f000000000000f03f", NA))
#> [1] TRUE   NA
```
