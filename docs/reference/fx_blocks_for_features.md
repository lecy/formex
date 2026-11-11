# Minimal set of feature blocks needed for a set of features

Given the features a fitted model uses, returns the blocks
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
must compute to produce them (always including `core`), so deployment
can skip the blocks it never reads.

## Usage

``` r
fx_blocks_for_features(features, manifest = fx_feature_manifest())
```

## Arguments

- features:

  Character vector of feature names.

- manifest:

  Feature manifest (default
  [`fx_feature_manifest()`](https://lecy.github.io/formex/reference/fx_feature_manifest.md)).

## Value

A character vector of block names.

## See also

[`fx_feature_manifest()`](https://lecy.github.io/formex/reference/fx_feature_manifest.md)
