# Triage a column for banking as a test case

Classifies a field into a quality verdict before it costs a label.
Corrupted and empty fields are excluded (with reasons); label-vs-value
mismatches are banked but flagged; clean fields are difficulty-rated.

## Usage

``` r
fx_triage_field(x, expected_data_type = NA, features = NULL)
```

## Arguments

- x:

  A column (any vector).

- expected_data_type:

  Optional `data_type` the corpus label implies (e.g. `"number"`);
  enables the numeric-vs-text mismatch check.

- features:

  Optional precomputed
  [`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
  row (avoids recomputation in a batch).

## Value

A list: `verdict` (`"garbage"` \| `"empty"` \| `"mismatch"` \| `"clean"`
\| `"hard"`), `keep` (bank it?), `reasons`, `difficulty`,
`noise_markers`.

## See also

[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
