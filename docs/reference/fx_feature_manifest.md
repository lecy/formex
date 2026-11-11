# Map each feature to its block and cascade tier

Returns the feature -\> block -\> tier lookup that makes
deployment-stage trimming mechanical: given the features a fitted model
references, look up their blocks and pass only those to
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md).

## Usage

``` r
fx_feature_manifest(lexicons = default_lexicons())
```

## Arguments

- lexicons:

  Named list of lexicons (default
  [`default_lexicons()`](https://lecy.github.io/formex/reference/default_lexicons.md)),
  included because they determine the lexicon-block feature names.

## Value

A data frame with `feature`, `block`, and `tier` columns.

## See also

[`fx_blocks_for_features()`](https://lecy.github.io/formex/reference/fx_blocks_for_features.md),
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
