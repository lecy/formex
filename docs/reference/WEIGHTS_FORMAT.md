# Signature axis weights tuned for format comparisons

A weighting for
[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md)
that emphasizes shape (rigidity, width, punctuation) and down-weights
cardinality to 0, because two formats of the same type differ in shape,
not in how many distinct values a column holds.

## Usage

``` r
WEIGHTS_FORMAT
```

## Format

A named numeric vector over the seven signature axes.

## See also

[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md),
[SIGNATURE_WEIGHTS](https://lecy.github.io/formex/reference/SIGNATURE_WEIGHTS.md)
