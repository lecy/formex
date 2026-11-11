# Is it an ISO 6709 lat/lon pair?

Tests whether each element is an ISO 6709 compact signed-decimal
coordinate pair, latitude then longitude, e.g. `"+40.7128-074.0060"` or
`"-33.8688+151.2093/"`. Both components carry an explicit leading sign
and there is no internal separator (the second sign delimits the pair),
which keeps it distinct from a comma-separated range or decimal pair.

## Usage

``` r
is_iso6709(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector: `TRUE` for a valid ISO 6709 pair in range, `FALSE`
otherwise, `NA` where `x` is `NA`.

## See also

[`is_coord_latlon()`](https://lecy.github.io/formex/reference/is_coord_latlon.md),
[`is_coord_lonlat()`](https://lecy.github.io/formex/reference/is_coord_lonlat.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other coordinate detectors:
[`is_coord_latlon()`](https://lecy.github.io/formex/reference/is_coord_latlon.md),
[`is_coord_lonlat()`](https://lecy.github.io/formex/reference/is_coord_lonlat.md)
