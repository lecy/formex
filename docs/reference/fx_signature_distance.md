# Weighted distance between two type signatures

A Gower-style weighted mean absolute difference over the axes both
signatures define. Axes that are `NA` in either signature are dropped
and the weights renormalized, so a column with no numeric content is not
penalized for lacking a numeric axis.

## Usage

``` r
fx_signature_distance(a, b, weights = SIGNATURE_WEIGHTS, per_axis = FALSE)
```

## Arguments

- a, b:

  Signatures from
  [`fx_type_signature()`](https://lecy.github.io/formex/reference/fx_type_signature.md).

- weights:

  Per-axis weights (default
  [SIGNATURE_WEIGHTS](https://lecy.github.io/formex/reference/SIGNATURE_WEIGHTS.md);
  see also
  [WEIGHTS_FORMAT](https://lecy.github.io/formex/reference/WEIGHTS_FORMAT.md)).

- per_axis:

  If `TRUE`, return the per-axis absolute differences instead of the
  aggregated distance.

## Value

A single distance in `[0,1]`, or a named per-axis vector.

## See also

[`fx_type_signature()`](https://lecy.github.io/formex/reference/fx_type_signature.md)
