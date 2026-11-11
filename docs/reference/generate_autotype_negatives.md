# Generate negative examples for a mutation tier

Produces `n_per_positive` mutated (likely-negative) strings for each
example in `P`, using mutation tier `"S1"`, `"S2"`, `"S3"`, or `"SP"`.

## Usage

``` r
generate_autotype_negatives(
  P,
  tier = c("S1", "S2", "S3", "SP"),
  n_per_positive = 10,
  p = 0.5,
  seed = NULL
)
```

## Arguments

- P:

  A character vector of positive examples.

- tier:

  One of `"S1"`, `"S2"`, `"S3"`, `"SP"`.

- n_per_positive:

  Number of mutants to attempt per positive.

- p:

  Per-character mutation probability.

- seed:

  Optional integer seed for reproducibility.

## Value

A character vector of unique mutated strings.
