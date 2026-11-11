# Default controlled-vocabulary lexicons for the lexicon feature block

The small, shippable lexicons `blk_lexicon` scores each column against,
including the public-domain person/place gazetteers (first/last name, US
city) that are the learned router's strongest features. Each named entry
becomes `lex_<name>_value` and `lex_<name>_token` rate features. Extend
by passing your own named list of character vectors to
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md).

## Usage

``` r
default_lexicons()
```

## Value

A named list of lowercase character vectors.

## See also

[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
