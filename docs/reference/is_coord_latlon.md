# Is it a latitude/longitude pair (latitude first)?

Tests whether each element is a two-part geographic coordinate with
latitude first, in either degrees-minutes-seconds form with N/S/E/W
hemisphere letters (`"40 deg 44' 55\" N, 74 deg 00' 22\" W"`) or
decimal-degree form (`"34.0522, -118.2437"`). Latitude must be in
`[-90, 90]` and longitude in `[-180, 180]`.

## Usage

``` r
is_coord_latlon(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector: `TRUE` for a lat-first coordinate pair in range,
`FALSE` otherwise, `NA` where `x` is `NA`.

## Details

A bracketed interval (`"[a, b]"`), a dashed/`to` range, a bare single
number, or an integer comma pair (`"10, 40"`) is rejected. DMS axis
order is read from the hemisphere letters; a decimal pair is
latitude-first unless the first value exceeds 90 (see
[`is_coord_lonlat()`](https://lecy.github.io/formex/reference/is_coord_lonlat.md)).

## See also

[`is_coord_lonlat()`](https://lecy.github.io/formex/reference/is_coord_lonlat.md),
[`is_iso6709()`](https://lecy.github.io/formex/reference/is_iso6709.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other coordinate detectors:
[`is_coord_lonlat()`](https://lecy.github.io/formex/reference/is_coord_lonlat.md),
[`is_iso6709()`](https://lecy.github.io/formex/reference/is_iso6709.md)
