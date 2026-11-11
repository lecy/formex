# Build a labelled test-case table for one data type

Assembles the pure inputs used by the bundled
[data_type_tests](https://lecy.github.io/formex/reference/data_type_tests.md)
object: the real positive examples plus deduplicated negatives from each
mutation tier, labelled by origin. Unlike
[`build_autotype_results()`](https://lecy.github.io/formex/reference/build_autotype_results.md),
this stores no detector predictions – it is the fixture a detector is
later scored against.

## Usage

``` r
generate_autotype_test_cases(
  P,
  data_type,
  tiers = c("S1", "S2", "S3", "SP"),
  n_per_positive = 20,
  p = 0.5,
  seed = 514
)
```

## Arguments

- P:

  A character vector of positive examples.

- data_type:

  A single string naming the type (e.g. `"currency_code"`).

- tiers:

  Mutation tiers to include.

- n_per_positive:

  Number of mutants to attempt per positive per tier.

- p:

  Per-character mutation probability.

- seed:

  Integer seed; set for reproducible fixtures.

## Value

A data frame with columns `data_type`, `case`, and `label`, where
`label` is `"valid"` for real positives or the tier name (`"S1"`,
`"S2"`, `"S3"`, `"SP"`) for negatives. Negatives coinciding with a real
positive are dropped.
