# Is it a GeoJSON geometry?

Is it a GeoJSON geometry?

## Usage

``` r
is_geojson(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a JSON object carrying a GeoJSON `"type"`
(`Point`, `Polygon`, `Feature`, `FeatureCollection`, ...) together with
a `"coordinates"`, `"geometry"`, `"geometries"`, or `"features"` member.
Structural (regex) check, not a full JSON parse.

## See also

Other geometry detectors:
[`is_wkb()`](https://lecy.github.io/formex/reference/is_wkb.md),
[`is_wkt_geometry()`](https://lecy.github.io/formex/reference/is_wkt_geometry.md)

## Examples

``` r
is_geojson(c('{"type":"Point","coordinates":[30,10]}', "{}", NA))
#> [1]  TRUE FALSE    NA
```
