# Score a column against every registered detector

Score a column against every registered detector

## Usage

``` r
score_data_type(values, detectors = data_type_detectors())
```

## Arguments

- values:

  A character vector (already sampled/deduped/cleaned).

- detectors:

  A named list of detector functions; defaults to the registry.

## Value

A data frame with `data_type`, `n`, `pass_rate`, ordered by descending
`pass_rate`.
