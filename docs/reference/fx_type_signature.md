# Reduce a column to its 7-number type signature

Collapses a column's value profile to seven interpretable axes, each
scaled to `[0,1]`: composition, numeric_gap, rigidity, width,
punctuation, tokenization, and cardinality. The signature is the
model-free router's view of a column and the input to
[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md).

## Usage

``` r
fx_type_signature(x, features = NULL)
```

## Arguments

- x:

  A column (coerced to character).

- features:

  Optional precomputed
  [`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
  row; computed from `x` when `NULL`.

## Value

A named numeric vector of the seven axes (`NA` where undefined).

## See also

[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md),
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
