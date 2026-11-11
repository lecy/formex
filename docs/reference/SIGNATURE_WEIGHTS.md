# Signature axis weights (balanced default)

Per-axis weights for
[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md).
Set an axis to 0 to ignore it, or raise one to emphasize it.
`SIGNATURE_WEIGHTS` weights all seven axes equally;
[WEIGHTS_FORMAT](https://lecy.github.io/formex/reference/WEIGHTS_FORMAT.md)
is tuned for format-level comparisons.

## Usage

``` r
SIGNATURE_WEIGHTS
```

## Format

A named numeric vector over the seven signature axes.

## See also

[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md),
[WEIGHTS_FORMAT](https://lecy.github.io/formex/reference/WEIGHTS_FORMAT.md)
