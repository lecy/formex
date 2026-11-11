# Extract features for every column of a data frame

Runs
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
on each column and row-binds the results into a single aligned feature
matrix (one row per column), filling block-gated gaps with `NA`.

## Usage

``` r
fx_extract_features_df(df, ...)
```

## Arguments

- df:

  A data frame (or list) of columns to profile.

- ...:

  Passed to
  [`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md).

## Value

A data frame with a leading `column` name and one feature row per input
column.

## See also

[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
