# Is it a longitude/latitude pair (longitude first)?

As
[`is_coord_latlon()`](https://lecy.github.io/formex/reference/is_coord_latlon.md)
but longitude first, the GeoJSON axis order
(`"74 deg 00' 22\" W, 40 deg 44' 55\" N"`, or decimal
`"-118.2437, 34.0522"`). For a decimal pair this fires only when the
first value unambiguously exceeds the latitude range (`|first| > 90`),
so a symmetric pair resolves to lat_lon.

## Usage

``` r
is_coord_lonlat(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector: `TRUE` for a lon-first coordinate pair in range,
`FALSE` otherwise, `NA` where `x` is `NA`.

## See also

[`is_coord_latlon()`](https://lecy.github.io/formex/reference/is_coord_latlon.md),
[`is_iso6709()`](https://lecy.github.io/formex/reference/is_iso6709.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other coordinate detectors:
[`is_coord_latlon()`](https://lecy.github.io/formex/reference/is_coord_latlon.md),
[`is_iso6709()`](https://lecy.github.io/formex/reference/is_iso6709.md)
