# Extract the value-profile feature vector for a column

Profiles a column into a wide, flat numeric feature row across a set of
independent, block-gated feature families (core, sequence, length,
character-class, punctuation, mask, character-frequency, regex, numeric,
token, lexicon, header). This is the substrate the learned router and
the signature primitives are built on. Extraction is reproducible (a
local, non-invasive RNG stream) so a profile is stable across runs.

## Usage

``` r
fx_extract_features(
  x,
  col_name = NULL,
  blocks = ALL_BLOCKS,
  lexicons = default_lexicons(),
  max_unique = 20000,
  seed = 1L
)
```

## Arguments

- x:

  A column (coerced to character).

- col_name:

  Optional column name; enables the `header` block features.

- blocks:

  Character vector of feature blocks to compute (default all). Compute
  only the blocks a fitted model references to trim deployment cost (see
  [`fx_feature_manifest()`](https://lecy.github.io/formex/reference/fx_feature_manifest.md),
  [`fx_blocks_for_features()`](https://lecy.github.io/formex/reference/fx_blocks_for_features.md)).

- lexicons:

  Named list of controlled vocabularies for the lexicon block (default
  [`default_lexicons()`](https://lecy.github.io/formex/reference/default_lexicons.md)).

- max_unique:

  Cap on distinct values profiled (downsampled above it).

- seed:

  Integer seed for the internal, caller-non-invasive RNG stream.

## Value

A one-row data frame of numeric/`NA` features.

## See also

[`fx_type_signature()`](https://lecy.github.io/formex/reference/fx_type_signature.md),
[`fx_feature_manifest()`](https://lecy.github.io/formex/reference/fx_feature_manifest.md)
