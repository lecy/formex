# Classify a column by its variable name

Matches a column header against the internal name lexicon
(`.name_lexicon`) and returns the best-matching ontology class. This
reaches the metadata-gated classes that value detectors cannot – it
reads the name, not the data – so it is a *suggestion*, weaker than a
value-signature match.

## Usage

``` r
classify_by_name(name, min_conf = 0.5)
```

## Arguments

- name:

  A single variable name (header string).

- min_conf:

  Minimum rule confidence for the top match to be reported as the guess;
  below it, `guess` is `NA`.

## Value

A list with:

- guess:

  Best-matching class name, or `NA`.

- ontology:

  Named vector `c(data_type, data_subtype, data_class, data_format)`;
  `data_format` is always `NA` (a name implies no format).

- confidence:

  The matched rule's confidence.

- candidates:

  Data frame of all matching rules, ranked by confidence.

- normalized:

  The normalized header actually matched against.

## See also

[`guess_column()`](https://lecy.github.io/formex/reference/guess_column.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

## Examples

``` r
classify_by_name("hourly_wage")$guess          # currency
#> [1] "currency"
classify_by_name("respondent_weight")$guess    # weight
#> [1] "weight"
classify_by_name("is_active")$guess            # indicator
#> [1] "indicator"
```
