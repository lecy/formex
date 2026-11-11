# Run a detector against positives and generated negatives

Scores `detector` on the real positives `P` and on negatives generated
at each mutation tier, returning one tidy table. Used to build the
human-readable artifacts in `data-types/`.

## Usage

``` r
build_autotype_results(
  detector,
  P,
  tiers = c("S1", "S2", "S3", "SP"),
  n_per_positive = 20,
  p = 0.5,
  seed = 514,
  threshold = 0.5
)
```

## Arguments

- detector:

  A function taking a character vector and returning a logical (or
  numeric score) vector.

- P:

  A character vector of positive examples.

- tiers:

  Mutation tiers to include.

- n_per_positive:

  Mutants attempted per positive per tier.

- p:

  Per-character mutation probability.

- seed:

  Integer seed.

- threshold:

  Score threshold used when `detector` returns numeric.

## Value

A data frame with columns `case`, `type` (`"valid"` or a tier),
`f_match` (raw detector output), and `f_predict` (logical prediction).
