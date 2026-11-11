# Guess a column's type from its values and its name

Runs both detection modalities and reconciles them VALUES-FIRST: if a
value detector clears `threshold`, its (format-anchored) answer is
returned; only when no value detector is confident does the name
classifier fill in the class. This is what lets the metadata-gated
classes – a `double` column named `sampling_weight`, a `0/1` column
named `eligible` – be typed at all, while never letting a misleading
name override a real value signature.

## Usage

``` r
guess_column(x, name = NULL, threshold = 0.8, ...)
```

## Arguments

- x:

  A vector (coerced to character) of column values.

- name:

  Optional variable name (header string).

- threshold:

  Minimum value-detector pass rate to trust the value guess.

- ...:

  Passed to
  [`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md).

## Value

A list with `source` (`"value"`, `"name"`, or `"none"`), `guess`,
`ontology` (the standard 4-vector), `confidence`, and the full `value`
and `name` sub-results for inspection.

## See also

[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md),
[`classify_by_name()`](https://lecy.github.io/formex/reference/classify_by_name.md)

## Examples

``` r
guess_column(c("06037", "36061"), name = "county")$source    # "value"
#> Warning: NAs introduced by coercion to integer range
#> [1] "value"
guess_column(c("3.4", "5.1", "7.8"), name = "sampling_weight")$guess  # weight
#> Warning: NAs introduced by coercion to integer range
#> [1] "weight"
```
